from utils.UtilsSmartsheet import UtilsSmartsheet
from utils.utils import run_setup, create_db_con
import pandas as pd
fn_name = 'sm_sheet'
logger = run_setup(fn_name, None)

# https://smartsheet-platform.github.io/smartsheet-python-sdk/index.html
api_key = 'pwjX4IjlEy9Krs2Ba0x4GTvekaQa4oSEV7o9j'
utils_sm = UtilsSmartsheet(api_key)
sheet_id = 5866821253025668# test 7977512583778180 {'BLZ': 1784708128001924}  Species BLZ 8586105326620548
sheet = utils_sm.ss_key.Sheets.get_sheet(sheet_id)
#print(sheet)
column_map = utils_sm.get_column_map(sheet)
all_fields=[]
for c, i in column_map.items():
    all_fields.append(c)
    print(c,end=',')
print(column_map)

for x in sheet.columns:
    if x.formula:
        print([key for key, val in column_map.items() if val == x.id] )#, x)

print(column_map['consent'])
#print([x.type for x in sheet.columns if x.ti == 1901872992702340][0])   --data type
#exit(1)

# Update rows validated pre-defined days ago
filter = {'name': ['=', 'ABC'], 'partner': ['=', 'par1'], 'admin3_ref_name': ['=', 'test_admin3']}
row_ids = utils_sm.get_filtered_row_ids(sheet, filter, logger)
upd_value = {'columnId': column_map['consent'], 'value': 'collaborative'}
if len(row_ids) > 0:
    logger.info(f'Update {len(row_ids)} rows {row_ids}')
    utils_sm.update_ss_rows(sheet_id, row_ids, upd_value, logger)
else:
    logger.info(f'No rows filtered')

exit(1)







