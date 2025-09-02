""" utils contains common utilities
"""
import boto3, logging, os, io, sys, shutil, json, zipfile, time
from aws_lambda_powertools import Logger
import requests, pytz
from datetime import datetime
from requests.auth import HTTPBasicAuth
import pandas as pd

bucket_name = "test_bucket"
s3 = boto3.resource('s3')

### Initialize ssm params
session = boto3.session.Session(region_name='us-east-1')
ssm_client = session.client('ssm')
s3_client = session.client("s3")
# WithDecryption=True would be set if using a SecureString in Parameter Store
kobo_login_param = ssm_client.get_parameter(Name='param_login', WithDecryption=True)['Parameter']['Value'] #used to download photos

gcp_credentials_param = 'test_g_drive'
sec_mgr_client = session.client('secretsmanager')
kw = {'SecretId': 'test_db_info'}
bfo_db_creds = sec_mgr_client.get_secret_value(**kw)
### End ----- Initialize ssm params

env_full = os.environ.get('AWS_EXECUTION_ENV', None)
env = 'AWS' if env_full is not None and env_full.find('AWS') > -1 else ''

# If running on cloud, downloading dependencies into tmp folder
if env == 'AWS':
    s3 = boto3.resource('s3')
    pkg_zip_list = ['rapidfuzz.zip', 'googleapiclient.zip', 'google.zip', 'misc.zip']

    for f in pkg_zip_list:
        s3.meta.client.download_file('test_bucket', 'utilities/'+f, '/tmp/'+f)
        with zipfile.ZipFile('/tmp/'+f, 'r') as zip_ref:
            zip_ref.extractall('/tmp/')
    #print(os.listdir('/tmp'))
    sys.path.insert(0, '/tmp/')

from googleapiclient import discovery
from googleapiclient.http import MediaFileUpload, MediaIoBaseDownload
from rapidfuzz import process, fuzz
import psycopg2
from prettytable import PrettyTable

def get_secret(param_name, repo):
    if repo == 'SSM':
        # WithDecryption=True would be set if using a SecureString in Parameter Store
        secret_info = json.loads(ssm_client.get_parameter(Name=param_name, WithDecryption=True)['Parameter']['Value'])
    elif repo == 'SEC':
        kw = {'SecretId': param_name}
        secret_info = sec_mgr_client.get_secret_value(**kw)
    return secret_info

def check_and_add_columns(table, schema, df_cols, cursor):
    sqlstr = f"select column_name from information_schema.columns where table_name = lower('{table}') and table_schema = '{schema}'"
    cursor.execute(sqlstr)
    res = cursor.fetchall()
    tbl_cols = [r[0].lower() for r in res] # get table columns from database
    diff_cols = [x.lower() for x in set(df_cols) if x.lower() not in tbl_cols]
    if len(diff_cols) > 0:
        for c in diff_cols:
            sqlstr = f"ALTER TABLE {schema}.{table} ADD COLUMN {c} VARCHAR NULL"
            cursor.execute(sqlstr)
        return f'\nColumn(s): {diff_cols} added in table {table}'
    else:
        return ''

def get_prettytable(tbl_type='validation', title='', fields=None):
    pretty_tbl = PrettyTable()
    pretty_tbl.align = "l"
    if title != '':
        pretty_tbl.title = title
    if tbl_type == 'validation':
        fields = {"STATUS": 50}
        field_name = list(fields.keys())[0]
        tbl_msg_len = fields[field_name]
        pretty_tbl.field_names = [field_name]
        pretty_tbl._min_width = fields
        pretty_tbl._min_table_width = tbl_msg_len
    elif tbl_type == 'default':
        pretty_tbl.field_names = list(fields.keys())    # fields is a dict of {field:len}. field_names is a list of field(s)
        pretty_tbl._max_width = fields                  # With of each field will appear as per value mentioned in fields dict
    return pretty_tbl

def get_google_creds():
    #Get Google service account credentials for the specified service account & shared folder id
    from google.oauth2 import service_account
    #session = boto3.session.Session(region_name='us-east-1')
    #ssm_client = session.client('ssm')

    # get_parameter returns a dictionary object of the json string, so convert it back to a string needed for getting the Google credentials object
    # WithDecryption=True would be set if using a SecureString in Parameter Store
    creds_dict = ssm_client.get_parameter(Name=gcp_credentials_param, WithDecryption=True)['Parameter']['Value']
    creds_json = json.loads(creds_dict)
    scopes_list = ['https://www.googleapis.com/auth/drive',
        'https://www.googleapis.com/auth/drive.file']
    credentials = service_account.Credentials.from_service_account_info(creds_json, scopes=scopes_list)
    service = discovery.build('drive', 'v3', credentials=credentials, cache_discovery=False)
    #if folder_id_parameter is not None:
    #    folder_id = ssm_client.get_parameter(Name=folder_id_parameter, WithDecryption=True)['Parameter']['Value']
    #    # build service
    #    return folder_id, service
    #else:
    return service

def list_files_google_drive(service, query):
    page_token = None
    files, lst_files = [], []
    #supportsAllDrives=True,includeItemsFromAllDrives=True, corpora='drive', driveId='0AAVNIeA_mDuBUk9PVA',
    while True:
        response = service.files().list(q=query,spaces='drive', pageToken=page_token, supportsAllDrives=True, includeItemsFromAllDrives=True,
                                        fields='nextPageToken, '
                                               'files(id, name)').execute()
        for file in response.get('files', []):
            lst_files.append(file)
        files.extend(response.get('files', []))
        page_token = response.get('nextPageToken', None)
        if page_token is None:
            break
    #print(lst_files)
    return lst_files

def s3_list_files(s3_bucket, prefix):
    response = s3_client.list_objects_v2(Bucket=s3_bucket, Prefix=prefix)
    # print(response)
    if 'Contents' in response:
        files = [obj['Key'] for obj in response['Contents']]
        print("Files:", files)
    else:
        print("No matching files found in the bucket")
        return
    return files, response

def s3_get_file(s3_bucket, prefix, file_nm, dest_path):
    dest_path = dest_path + file_nm
    try:
        s3_client.download_file(s3_bucket, f'{prefix}/{file_nm}', dest_path)
    except Exception as e:
        raise RuntimeError('Problem in downloading file: ', e)
    return 0

def upload_to_google_drive(service, folder_id, file_path, description):
    file_name = os.path.basename(file_path)
    if file_name.split('.')[-1] in ('jpg', 'jpeg'):
        mime_type = 'image/jpeg'
    else:
        mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

    # Uploads a file to Google Drive to the designated folder in a shared drive.
    media_body = MediaFileUpload(file_path, mimetype=mime_type)
    body = {'name': file_name,
            'title': file_name,
            'description': description,
            'mimeType': mime_type,
            'parents': [folder_id]}
    # note that supportsAllDrives=True is required or else the file upload will fail
    file = service.files().create(
        supportsAllDrives=True, body=body,
        media_body=media_body).execute()
    # print('Uploaded {}, {}'.format(file_name, file['id']))
    return file

def copy_file_gdrive(service, file_id, newfile):
    # This fn copies a file to a given target name & folder
    response = service.files().copy(fileId=file_id, body=newfile, supportsAllDrives=True).execute()
    return response

def update_file_google_drive(service, file_id, file_path):
    try:
        mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        media_body = MediaFileUpload(file_path, mimetype=mime_type)
        file = service.files().update(
            fileId=file_id,
            media_body=media_body, supportsAllDrives=True, uploadType='resumable').execute()
        return file
    except Exception as error:
        exception_type, exception_object, exception_traceback = sys.exc_info()
        line_number = exception_traceback.tb_lineno
        msg = "Error: line# %s, %s, %s" % (line_number, exception_type, error)
        raise RuntimeError('Problem in update file in g-drive - ' + str(msg))

def delete_from_google_drive(service, file):
    service.files().delete(fileId=file.get("id")).execute()
    print('...............deleting now')
    #service.files().update(fileId=file.get("id"), body={'trashed': True}, supportsAllDrives=True).execute()
    print(f'Deleted {file.get("name")} from google drive')
    service.files().emptyTrash().execute()

def google_drive_moveFile(service, file, new_folder_id):
    try:
        fileId = file.get("id")
        # Retrieve the existing parents to remove
        file = service.files().get(fileId=fileId, fields="parents", supportsAllDrives=True).execute()
        previous_parents = ",".join(file.get("parents"))
        #print('2--', previous_parents)
        # Change parent to move file to new folder
        file = service.files().update(fileId=fileId, addParents=new_folder_id, removeParents=previous_parents,
                fields="id, parents", supportsAllDrives=True).execute()
        return f'File moved to {file.get("parents")}'
    except Exception as error:
        return print('Error while moving file:', error)

def download_from_google_drive(service, file, dest_path):
    file_id, file_name = file.get("id"), file.get("name")
    request = service.files().get_media(fileId=file_id)
    fh = io.BytesIO()
    # Initialise a downloader object to download the file
    downloader = MediaIoBaseDownload(fh, request, chunksize=204800)
    done = False
    try:
        # Download the data in chunks
        while not done:
            status, done = downloader.next_chunk()
        fh.seek(0)
        dest_path = dest_path + file_name
        # Write the received data to the file
        with open(dest_path, 'wb') as f:
            shutil.copyfileobj(fh, f)
        print("Downloaded:",file_name)
        # Return True if file Downloaded successfully
        return True
    except Exception as error:
        # Return False if something went wrong
        print("Something went wrong. ", error)
        return False

# This fn creates a file in shared drive in cloud
def generate_file(df, header, file, logger):
     try:
        temp_dir = '/tmp/' if env == 'AWS' else ''
        sf_file_lambda_path = temp_dir + file['file_nm']

        # Create a Pandas Excel writer using XlsxWriter as the engine
        writer = pd.ExcelWriter(sf_file_lambda_path, engine='xlsxwriter')
        # Convert the dataframe to an XlsxWriter Excel object
        df.to_excel(writer, sheet_name='Sheet1', index=False)
        # Get the xlsxwriter objects from the dataframe writer object.
        workbook = writer.book
        worksheet = writer.sheets['Sheet1']

        # Adding formatting
        header_format = workbook.add_format({'bold': True, 'bg_color': '#00FF00'})

        for col_num, data in enumerate(header):
            worksheet.write(0, col_num, data, header_format)
            worksheet.set_column(col_num, col_num, 20)  # Set width of columns

        worksheet.freeze_panes(1, 0)  # Freezing header row
        # Close the Pandas Excel writer and output the Excel file
        writer.close()
        ### End preparing partner QA data

        # Get google creds & folder id, build service & upload file to google drive
        service = get_google_creds()
        # We need to update/overwrite same file for Smartsheet
        update_file_google_drive(service, file['file_id'], sf_file_lambda_path)

        # Removing local file after upload
        os.remove(sf_file_lambda_path)
        return 0
     except Exception as error:
        exception_type, exception_object, exception_traceback = sys.exc_info()
        line_number = exception_traceback.tb_lineno
        msg = "Error: line# %s, %s, %s" % (line_number, exception_type, error)
        raise RuntimeError('Problem in file generation - ' + str(msg))

def info_no_record_found(fn_name, from_address, to_address, cursor, logger):
    tracking_table = 'api_fetch_logging'
    subject = f'Success. {fn_name}: No eligible data found'
    logger.info(subject)

    # Logging successful run
    sqlstr = """(form_name, max_extracted_ts, count_extracted, main_insert_count, message, start_dt, end_dt) VALUES (%s,%s,%s,%s,%s,%s,%s)"""
    record_to_insert = (fn_name, None, 0, None, subject, current_cst(), current_cst())
    insert_rec(tracking_table, sqlstr, record_to_insert, cursor)
    # remove records to keep #rows in check
    cleanup(tracking_table, cursor, fn_name, logger=logger)
    if env == 'AWS':
        send_email(subject, subject, from_address, to_address=to_address)
    return

def current_cst():
    cst_tz = pytz.timezone('US/Central')
    return datetime.now().astimezone(cst_tz).strftime("%Y-%m-%d %H:%M:%S")  # CST timestamp

def fn_get_match_score(x, c_ref_data, ref_match_limit):
    if x is None or len(x.strip()) == 0:
        return ''
    c_ref_data_t = {item.title() for item in c_ref_data}
    # Fetch only required matching count using fuzzy library
    e = process.extract(x.title(), c_ref_data_t, limit=ref_match_limit)
    return e

def send_email(subject, body, from_address, to_address):
    # Attempt sending email to each address individually as doing all-in-1 attempt
    # will fail in case any email id is not verified/bad
    for to_addr in to_address:
        try:
            to_address = to_addr.split()
            client = boto3.client('ses')
            response = client.send_email(
                Source=from_address,
                Destination={'ToAddresses': to_address},
                Message={
                    'Subject': {
                        'Data': subject
                    },
                    'Body': {
                        'Text': {
                            'Data': body
                        }
                    }
                })
            if response['ResponseMetadata']['HTTPStatusCode'] != 200:
                print('Error sending email to %s: Emailing status : %s : %s' % (
                to_address, response['ResponseMetadata']['HTTPStatusCode'], response))
            else:
                print('Mail sent successfully to %s' % (to_address))
        except (Exception, psycopg2.Error) as error:
            print('Problem sending email to %s:  %s'% (to_address,error) )
    return

def send_email_html(subject, body_html, from_address, to_address ):
    # Attempt sending email to each address individually as doing all-in-1 attempt
    # will fail in case any email id is not verified/bad
    BODY_HTML = """<html>   <head> <style> 
                        caption {font-weight:bold;font-size: 120%%;}
                        table, th, td   {
                          border: 1px solid black;
                          border-collapse: collapse;
                                        }
                        </style> </head>
                        <body>
                            <p>%s</p>
                        </body>  
                    </html>""" % (body_html)
    CHARSET = "UTF-8"
    for to_addr in to_address:
        try:
            to_address = to_addr.split()
            client = boto3.client('ses')
            response = client.send_email(
                Source=from_address,
                Destination={'ToAddresses': to_address},
                Message={
                    'Subject': {
                        'Data': subject
                    },
                    'Body': {
                        'Text': {
                            'Data': 'dummy'
                        },
                    'Html': {
                        'Charset': CHARSET,
                        'Data': BODY_HTML,
                    }
                    }
                })
            if response['ResponseMetadata']['HTTPStatusCode'] != 200:
                print('Error sending email to %s: Emailing status : %s : %s' % (
                to_address, response['ResponseMetadata']['HTTPStatusCode'], response))
            else:
                print('Mail sent successfully to %s' % (to_address))
        except (Exception, psycopg2.Error) as error:
            print('Problem sending email to %s:  %s'% (to_address,error) )
    return

def create_db_con(fn_name, logger):
    try:
        value = json.loads(bfo_db_creds['SecretString'])
        #value = eval(parameters.get_secret("bfo_info"))
        if env == 'AWS':
            connection = psycopg2.connect(user=value["username"], password=value["password"], host=value["host"],
                                          port=value["port"], database=value["engine"], application_name=f"AWS lambda run ({fn_name})")
        else:
            connection = psycopg2.connect(user=value["username"],   password=value["password"], host=value["host"],
                                      port=value["port"],       database=value["engine"], application_name=f"Local run ({fn_name})")
    except (Exception, psycopg2.Error) as error:
        logger.info('Problem in DB connection', error)
        exit(1)
    logger.info('DB connection successful - ' + value["host"] + '/' + value["engine"])
    return connection

def create_read_db_con(fn_name, logger):
    try:
        kw = {'SecretId': 'test_read_db_info'}
        bfo_db_creds = sec_mgr_client.get_secret_value(**kw)
        value = json.loads(bfo_db_creds['SecretString'])
        #value = eval(parameters.get_secret("bfo_info"))
        if env == 'AWS':
            connection = psycopg2.connect(user=value["username"], password=value["password"], host=value["host"],
                                          port=value["port"], database=value["engine"], application_name=f"AWS lambda run ({fn_name})")
        else:
            connection = psycopg2.connect(user=value["username"],   password=value["password"], host=value["host"],
                                      port=value["port"],       database=value["engine"], application_name=f"Local run ({fn_name})")
    except (Exception, psycopg2.Error) as error:
        logger.info('Problem in DB connection', error)
        exit(1)
    logger.info('DB connection successful - ' + value["host"] + '/' + value["engine"])
    return connection

def cleanup(table, cursor, form_name, n=150, logger=None):
    sqlstr = "DELETE FROM %s WHERE max_extracted_ts is NULL and DATE_PART('day',CURRENT_TIMESTAMP - end_dt) > %s and\
                form_name = '%s' " % (table, n, form_name)
    cursor.execute(sqlstr)
    count = cursor.rowcount
    logger.info(f'Cleanup: {count} record(s) deleted successfully from {table}')

def cleanup_tbl(table, column, cursor, num_days=60, filter='', logger=None):
    cursor.execute(f"DELETE FROM {table} "
                   f"WHERE DATE_PART('day',CURRENT_TIMESTAMP - {column}) > {num_days}  {filter}")
    count = cursor.rowcount
    logger.info(f'Cleanup_tbl: {count} record(s) deleted successfully from {table}')

def insert_rec(table, sqlstr, record_to_insert, cursor):
    tbl = 'INSERT INTO %s ' % table
    sqlstr = tbl + sqlstr + ' RETURNING id; '
    cursor.execute(sqlstr, record_to_insert)
    returned_id = cursor.fetchone()
    return returned_id

def update_table(table, sqlstr, record_to_update, cursor):
    upd_sqlstr = f'UPDATE {table} SET {sqlstr}'
    cursor.execute(upd_sqlstr, record_to_update)
    return 0

def get_max_value(load_table, column_name, cursor, filter=None):
    try:
        sqlstr = f"select max({column_name}) from {load_table} "
        if filter is not None:
            sqlstr = f"select max({column_name}) from {load_table} WHERE {filter} "
        cursor.execute(sqlstr)
        return cursor.fetchone()[0]
    except (Exception, psycopg2.Error) as error:
        print('Problem in get_max_value', error)

def is_active(job_name, cursor):
    try:
        cursor.execute(f"select is_active from job_lookup WHERE job_name='{job_name}'")
        return cursor.fetchone()[0]
    except:
        return False

def ifnull(var, default):
  if var is None:
    return default
  return var

def run_setup(name, env=None):
    try:
        if env == 'AWS':
            logger = Logger(log_record_order=["timestamp","location","message","service"], datefmt='%Y-%m-%d_%H:%M:%S',\
                            utc=True, service=name)
        elif env is None:
            logger = logging.getLogger(name)
            logger.setLevel(logging.INFO)
            logging.basicConfig(
                level=logging.INFO, datefmt='%Y-%m-%d_%H:%M:%S',
                format="%(asctime)s - %(name)s - %(module)s - %(lineno)s - %(message)s"
            )
            #console_log_handler = logging.StreamHandler(stream=sys.stdout)
            #logger.addHandler(console_log_handler)
        else:
            print('Error in setting logging')
    except Exception as err:
        print('Error:', err)
    return logger

def get_ssm_param(param_name):
    session = boto3.session.Session(region_name='us-east-1')
    ssm_client = session.client('ssm')
    # WithDecryption=True would be set if using a SecureString in Parameter Store
    param = ssm_client.get_parameter(Name=param_name, WithDecryption=True)['Parameter']['Value']
    return param

def get_photo(new_species_photo, attachments, upload_dest, gcp_upload_folder_id, gcp_upload_path, service, s3_upload_path, submission_id,
              cnt_photos, cnt_photos_found, cnt_photos_notfound, downloaded_files=None, refresh_load=0):
    attachment_found = 0    # this will assist in maintaining counter for photos
    # loop thru list of dictionaries to find url path for file
    for a in attachments:
        if a['filename'].find(new_species_photo) > -1:
            attachment_found = 1
            file_url_path = a['filename'].replace('/', '%2F')
            url = 'https://kc.kobotoolbox.org/media/large?media_file=' + file_url_path
            if upload_dest == 'gcp':
                params = (gcp_upload_folder_id, gcp_upload_path, service)
                # In case of refresh, Download the photo only if it's not already downloaded. This will save time.
                # if already downloaded, just build URL for table insertion
                if refresh_load == 0:
                    new_species_photo = download_and_get_path(upload_dest, url, str(submission_id), new_species_photo, params)
                if refresh_load == 1 and str(submission_id) + '_' + new_species_photo not in downloaded_files.keys():
                    new_species_photo = download_and_get_path(upload_dest, url, str(submission_id), new_species_photo, params)
                elif refresh_load == 1 and str(submission_id) + '_' + new_species_photo in downloaded_files.keys():
                    new_species_photo = 'https://drive.google.com/uc?export=view&id=' + \
                                        downloaded_files[str(submission_id) + '_' + new_species_photo] + '|' + new_species_photo
            if upload_dest == 'aws':
                params = (s3_upload_path)
                new_species_photo = download_and_get_path(upload_dest, url, str(submission_id), new_species_photo, params)
    # If photo is not found, log the message
    new_species_photo = new_species_photo + ' - attachment missing in kobo record' if attachment_found == 0 else new_species_photo
    # Photo(s) counters
    cnt_photos = cnt_photos + 1 if len(new_species_photo) > 1 and new_species_photo.find('.jpg') else cnt_photos
    cnt_photos_found = cnt_photos_found + 1 if attachment_found == 1 else cnt_photos_found
    cnt_photos_notfound = cnt_photos_notfound + 1 if attachment_found == 0 else cnt_photos_notfound

    return new_species_photo, cnt_photos, cnt_photos_found, cnt_photos_notfound

def download_and_get_path(dest, url, sub_id, file_nm, params):
    try:
        # Get image data from url using BasicAuth-creds
        img_data = requests.get(url, auth=HTTPBasicAuth(kobo_login_param.split(',')[0], kobo_login_param.split(',')[1])).content
        if len(img_data) == 0:
            raise Exception('Zero photo size. Check credentials.')

        dest_path = '/tmp/' if env == 'AWS' else ''
        lambda_file_path = dest_path + sub_id + '_' + file_nm
        f = open(lambda_file_path, 'wb')
        f.write(img_data)
        f.close()
        upload_folder_id = params[0]
        if dest == 'aws':
            s3_path = upload_folder_id + sub_id + '_' + file_nm
            s3.meta.client.upload_file(lambda_file_path, bucket_name, s3_path)
            os.remove(lambda_file_path)
            return os.path.basename('s3://' + bucket_name + '/' + s3_path)
        elif dest == 'gcp':
            service = params[2]
            file = upload_to_google_drive(service, upload_folder_id, lambda_file_path, lambda_file_path)
            os.remove(lambda_file_path)
            return 'https://drive.google.com/uc?export=view&id=' + file['id'] + '|' + file['name']
        else:
            raise Exception(f"Invalid destination specified {dest}")
    except Exception as error:
        exception_type, exception_object, exception_traceback = sys.exc_info()
        line_number = exception_traceback.tb_lineno
        raise Exception(f"Error in downloading photo {file_nm} for sub_id {sub_id}: line# %s :  %s %s" % (line_number, exception_type, error))

def fetch_table_data(cursor, sqlstr):
    try:
        cursor.execute(sqlstr)
        data = cursor.fetchall()
        return data
    except (Exception, psycopg2.Error) as error:
        raise Exception('Problem in fetching data', error)

def clean_vals(x, criteria):
    if x is not None:
        if criteria.find('strip') > -1:
            x = x.strip()
        if criteria.find('lower') > -1:
            x = x.lower()
        if criteria.find('upper') > -1:
            x = x.upper()
        if criteria.find('remove_underscore') > -1:
            x = x.replace('_', '')
    return x

def time_it(func):
    def wrapper(*args, **kwargs):
        begin = time.time()
        original_result = func(*args, **kwargs)
        print(f'WRAPPER--> {func.__name__} took {round(time.time()-begin)} sec to finish.')
        return original_result
    return wrapper
