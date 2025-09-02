"""
v1.0: This class stores functions for interacting with given Smartsheet(s)
"""
import boto3, os, sys

env_full = os.environ.get('AWS_EXECUTION_ENV', None)
env = 'AWS' if env_full is not None and env_full.find('AWS') > -1 else ''

# If running on cloud, downloading dependencies into tmp folder
if env == 'AWS':
    s3 = boto3.resource('s3')
    #pkg_zip_list = ['googleapiclient.zip', 'google.zip', 'misc.zip']
    #for f in pkg_zip_list:
    #    s3.meta.client.download_file('barefootocean', 'utilities/'+f, '/tmp/'+f)
    #    with zipfile.ZipFile('/tmp/'+f, 'r') as zip_ref:
    #        zip_ref.extractall('/tmp/')
    #print(os.listdir('/tmp'))
    sys.path.insert(0, '/tmp/')

import smartsheet
import pandas as pd
import gc

class UtilsSmartsheet():
    NAMES_QA_SHEETS = {'BLZ': 5986772479594372, 'CV': 6923573566328708, 'GMB': 978802712727428, 'KEN': 7855117613092740,
                       'PHL': 4242351111229316, 'SEN': 2419973938958212, 'TZA': 8956945301983108,
                       'IDN': 7528129941688196, 'TL': 887706775146372, 'MDG': 3452806467899268}
    SPECIES_QA_SHEETS = {'BLZ': 8442853822779268, 'CV': 4484148106317700, 'GMB': 5482402340097924, 'KEN': 7178641205055364,
                         'PHL': 6973032530661252, 'SEN': 4079623390318468, 'TZA': 3468066218266500,
                         'IDN': 3753094206672772, 'TL': 1418212545613700, 'MDG': 5663043614625668}
    WARNINGS_QA_SHEETS = {'BLZ': 3695019001073540, 'CV': 8730042179735428, 'GMB': 3230602526412676, 'KEN': 1129424581775236,
                          'IDN': 3045853753200516}
    GIS_MGMT_QA_SHEETS = {'IDN': 3612956219625348, 'KEN': 4282684940439428, 'GMB': 5854655855677316,
                          'MDG': 2126336479940484, 'TLS': 8001538208255876, 'TZA': 201297778134916,
                          'BLZ': 8078680115859332, 'CV': 6934449288597380}
    buyer_ref_SHEETS = {'buyer_ref_BLZ': 2502283375890308, 'buyer_ref_CV': 2274322282401668, 'buyer_ref_GMB': 5109654895939460,
                        'buyer_ref_KEN': 894834436951940, 'buyer_ref_IDN': 5866821253025668,'buyer_ref_PHL': 6770330974506884,
                        'buyer_ref_SEN': 885911508176772,'buyer_ref_TL': 6102408799145860,'buyer_ref_TZA': 5138044977893252,
                        'buyer_ref_MDG_ABJ': 4274883034828676,'buyer_ref_MDG_BSM': 904381679488900,
                        'buyer_ref_MDG_MHJ': 3463701151567748,'buyer_ref_MDG_MNT': 7757792274239364,
                        'buyer_ref_MDG_SW': 7546462703406980}

    def __init__(self, api_key):
        self._cfg = {'api_key': api_key,
                      'value_cols': ['Assigned User']}
        self.ss_key = smartsheet.Smartsheet(self._cfg['api_key'])
        self.ROW_DELETE_LIMIT = 400                     # Batch limit for deleting rows
        self.ROW_INSERT_LIMIT = 5000                    # Batch limit for inserting rows
        self.MAX_UNVALIDATED_LIMIT = 10000              # If #rows is below this, then only we will remove them in a given run
        self.ARCH_THRESHOLD_SS = 7                      # Rows validated rows before this interval will be removed
        self.ss_key.errors_as_exceptions(True)
        self.RETRY_CNT = 2

    # This fn uses retry mechanism to initialize the sheet in case of any exception like bad gateway, network issue etc
    def initialize_sheet(self, sheet_id, logger):
        sheet, msg, r_msg = None, '', ''
        for i in range(0, self.RETRY_CNT+1):
            try:
                sheet = self.ss_key.Sheets.get_sheet(sheet_id)      # Initialize instance of the specific sheet id
                break
            except Exception as error:
                exception_type, exception_object, exception_traceback = sys.exc_info()
                line_number = exception_traceback.tb_lineno
                if i >= self.RETRY_CNT:
                    msg = "Error: line# %s, %s, %s. Failed to initialize sheet after %s attempts"\
                            % (line_number, exception_type, error, self.RETRY_CNT)
                    logger.info(msg)
                    r_msg = r_msg + msg
                    raise RuntimeError(str(r_msg))
                msg = f"****** Error:{error}. Retrying-{i} ss initialization. Line#: {line_number}."
                logger.info(msg)
                r_msg = r_msg + msg
                continue
        return sheet, r_msg

    # This fn attempts Retry logic for several Smartsheet operations
    def exec_operation(self, operation, sheet_id, IN_sheet, rows, logger):
        OUT_sheet, msg, r_msg, result = None, '', '', None
        for i in range(0, self.RETRY_CNT+1):
            try:
                if operation == 'get_sheet':
                    OUT_sheet = self.ss_key.Sheets.get_sheet(sheet_id)      # Initialize instance of the specific sheet id
                if operation == 'delete_rows':
                    IN_sheet.delete_rows(rows, True)
                if operation == 'add_rows':
                    result = IN_sheet.add_rows(rows)
                break
            except Exception as error:
                exception_type, exception_object, exception_traceback = sys.exc_info()
                line_number = exception_traceback.tb_lineno
                if i >= self.RETRY_CNT:
                    msg = f"Error: line# %s, %s, %s. Failed {operation} after %s attempts"\
                            % (line_number, exception_type, error, self.RETRY_CNT)
                    logger.info(msg)
                    r_msg = r_msg + msg
                    raise RuntimeError(str(r_msg))
                msg = f"****** Error:{error}. Retrying-{i} {operation}. Line#: {line_number}."
                logger.info(msg)
                r_msg = r_msg + msg
                continue
        return OUT_sheet, r_msg, result

    def get_column_map(self, sheet):
        # This fn returns a dict with column name and id
        column_map = {}
        for column in sheet.columns:
            column_map[column.title] = column.id
        return column_map

    def get_sheet_as_df(self, sheet, logger):
        # This fn returns the sheet as a dataframe
        logger.info(f"Sheet as df: {sheet.name}")
        col_names = [col.title for col in sheet.columns]
        rows = []
        for row in sheet.rows:
            cells = []
            for cell in row.cells:
                cells.append(cell.value)
            rows.append(cells)
        data_frame = pd.DataFrame(rows, columns=col_names)
        del sheet
        gc.collect()
        return data_frame

    def get_filtered_row_ids(self, sheet, row_filter, logger):
        filter_dict = {}
        column_map = self.get_column_map(sheet)  # Getting column_name:column_id(numeric) mapping for Smartsheet
        for col_name, col_value in row_filter.items():
            filter_dict[column_map[col_name]] = col_value  # Smartsheet filter requires column_id(numeric) e.g. {8657272433758084: ['=', None]}

        # This fn applies filter on sheet as per column, operator & value and returns a list of row ids
        filtered_row_ids = []
        for row in sheet.rows:
            match = True
            for cell in row.cells:
                for col_id, filter_operator_and_value in filter_dict.items():
                    operator = filter_operator_and_value[0]
                    value = filter_operator_and_value[1]
                    if cell.column_id == col_id and operator == '=' and cell.value != value:
                        match = False
                    if cell.column_id == col_id and operator == '>' and cell.value <= value:
                        match = False
                    if cell.column_id == col_id and operator == '<' and cell.value >= value:
                        match = False
                    if cell.column_id == col_id and operator == '!=' and cell.value == value:
                        match = False
                    #if cell.column_id in (8276456306331524,4335806632382340):
                    #   print('..params - ', cell.column_id, cell.value, 'Vs', value, match)
            if match == True:
                filtered_row_ids.append(row.id)
        return filtered_row_ids

    def smartsheet_insert_wrapper(self, df, sheet, logger):
        # Wrapper fn for inserting rows into SS either in a single run or in batches
        if len(df.axes[0]) <= self.ROW_INSERT_LIMIT:
            self.add_rows_to_smartsheet(df, sheet, logger)                      # Adding rows to Smartsheet
        else:
            logger.info(f'{sheet.name}: Doing batch-wise insertion of rows')
            df = df.reset_index()  # make sure indexes pair with number of rows
            col_list = list(df.columns)
            col_list.remove('index')  # removing column named index
            i = 0
            # Loop to insert into Smartsheet in Batches
            while i <= len(df.axes[0]):
                start = i
                end = i + self.ROW_INSERT_LIMIT - 1
                df_limited = df.loc[start:end, col_list]
                self.add_rows_to_smartsheet(df_limited, sheet, logger)          # Adding rows to Smartsheet
                i = end + 1
        return

    def add_rows_to_smartsheet(self, data_df, sheet, logger):
        # Main fn for inserting rows into SS. Prepares row as required by SS. Converts NULL/None to a BLANK value
        try:
            column_map = self.get_column_map(sheet)
            data_dict = data_df.to_dict('index')
            rowsToAdd = []
            for j, i in data_dict.items():
                new_row = self.ss_key.models.Row()
                new_row.to_bottom = True
                for k, v in i.items():
                    new_cell = self.ss_key.models.Cell()
                    new_cell.column_id = column_map[k]
                    new_cell.value = "" if v in ('', None) else v  # Smartsheet cell does not take NULL or BLANK value
                    #if [x.type for x in sheet.columns if x.id == new_cell.column_id][0] == 'DATE':
                    # add the cell object to the row object
                    new_row.cells.append(new_cell)
                # add the row object to the collection of rows
                rowsToAdd.append(new_row)

            # add the collection of rows to the sheet in Smartsheet
            #result = sheet.add_rows(rowsToAdd)
            _, _, result = self.exec_operation('add_rows', sheet_id=None, IN_sheet=sheet, rows=rowsToAdd, logger=logger)
            logger.info(f"Added {len(data_df.axes[0])} rows to {sheet.name}")
            return result
        except Exception as error:
            exception_type, exception_object, exception_traceback = sys.exc_info()
            line_number = exception_traceback.tb_lineno
            msg = "Error: line# %s, %s, %s" % (line_number, exception_type, error)
            raise RuntimeError('Problem in adding rows to smartsheet - ' + str(msg))

    def smartsheet_delete_wrapper(self, filtered_row_ids, count_filtered_row_ids, sheet, logger):
        # Wrapper fn for deleting rows from SS either in a single run or in batches
        row_ids_limited = []
        if count_filtered_row_ids <= self.ROW_DELETE_LIMIT:
            #sheet.delete_rows(filtered_row_ids, True)
            self.exec_operation('delete_rows', sheet_id=None, IN_sheet=sheet, rows=filtered_row_ids, logger=logger)
        else:
            logger.info(f'{sheet.name}: Doing batch-wise row removal')
            for row_id in filtered_row_ids:
                row_ids_limited.append(row_id)
                if len(row_ids_limited) % self.ROW_DELETE_LIMIT == 0:
                    #sheet.delete_rows(row_ids_limited, True)  # Batch-wise removal of un-validated rows from Smartsheet
                    self.exec_operation('delete_rows', sheet_id=None, IN_sheet=sheet, rows=row_ids_limited, logger=logger)
                    row_ids_limited = []  # reset list
            if len(row_ids_limited) > 0:
                #sheet.delete_rows(row_ids_limited, True)  # Remove remaining un-validated rows
                self.exec_operation('delete_rows', sheet_id=None, IN_sheet=sheet, rows=row_ids_limited, logger=logger)
        return

    def fetch_table_data(self, cursor, sqlstr):
        cursor.execute(sqlstr)
        data = cursor.fetchall()
        return data
    def delete_uv_rows(self, sheet, remove_filter, logger):
        # Wrapper fn for checking unvalidated rows, calling row delete fn
        '''filter_dict = {}
        column_map = self.get_column_map(sheet)  # Getting column_name:column_id(numeric) mapping for Smartsheet
        for col_name, col_value in remove_filter.items():
            filter_dict[column_map[col_name]] = col_value  # Smartsheet filter requires column_id(numeric) e.g. {8657272433758084: ['=', None]}
        '''
        # Getting un-validated row ids as per filter
        filtered_row_ids = self.get_filtered_row_ids(sheet, remove_filter, logger)
        count_filtered_row_ids = len(filtered_row_ids)

        row_ids = []
        for x in sheet.rows:
            row_ids.append(x.id)  # Store all row ids from sheet

        # if current #UV is more than max set limit, we will not modify the sheet & will continue with next one
        max_uv_limit = self.MAX_UNVALIDATED_LIMIT
        if count_filtered_row_ids >= max_uv_limit:
            logger.info(f'{sheet.name}: #Unvalidated rows: {count_filtered_row_ids} >= max limit({max_uv_limit}). Skipping.')
            return None

        logger.info(f'{sheet.name}: Removing {count_filtered_row_ids} un-validated rows as per filter')
        if count_filtered_row_ids > 0:
            self.smartsheet_delete_wrapper(filtered_row_ids, count_filtered_row_ids, sheet, logger)
            logger.info(f'{sheet.name}: Deleted: {count_filtered_row_ids} rows out of total {len(row_ids)}')
        else:
            logger.info(f'{sheet.name}: No eligible data found for deletion as per filter')
        return count_filtered_row_ids

    def delete_rows(self, sheet, row_ids, logger):
        # This fn will remove given row ids from the sheet
        if len(row_ids) > 0:
            self.smartsheet_delete_wrapper(row_ids, len(row_ids), sheet, logger)
            logger.info(f'{sheet.name}: Deleted: {len(row_ids)} rows')
        else:
            logger.info(f'{sheet.name}: No row ids found for deletion')
        return

    # fn to update given row_ids with passed new cell values (e.g: upd_value = {'columnId': <col id>, 'value': <new value>})
    def update_ss_rows(self, sheet_id, row_ids, upd_value, logger):
        try:
            row_to_update = smartsheet.models.Row()
            for row_id in row_ids:
                row_to_update.id = row_id
                row_to_update.cells.append(upd_value)
                # Update the row
                response = self.ss_key.Sheets.update_rows(sheet_id,[row_to_update])
                logger.info(f"Updated row: {response.message}")
            return 0
        except Exception as error:
            exception_type, exception_object, exception_traceback = sys.exc_info()
            line_number = exception_traceback.tb_lineno
            msg = "Error: line# %s, %s, %s" % (line_number, exception_type, error)
            raise RuntimeError('Problem in updating rows in smartsheet - ' + str(msg))
