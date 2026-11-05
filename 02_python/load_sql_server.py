"""Optional SQL Server CSV loader. Requires pip install pyodbc and an installed ODBC Driver 18."""
import argparse, csv
from pathlib import Path
import pyodbc

root=Path(__file__).resolve().parents[1] / '01_data'
tables=['DimResort','DimMember','FactReservation','FactPointsLedger','FactContactCenter','DimComplianceRule']
parser=argparse.ArgumentParser()
parser.add_argument('--server',required=True,help='e.g. localhost\\SQLEXPRESS')
parser.add_argument('--database',default='VacationClubCompliance')
parser.add_argument('--trusted',action='store_true',help='Windows integrated auth')
parser.add_argument('--user');parser.add_argument('--password')
args=parser.parse_args()
conn=f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={args.server};DATABASE={args.database};Encrypt=yes;TrustServerCertificate=yes;'
conn+= 'Trusted_Connection=yes;' if args.trusted else f'UID={args.user};PWD={args.password};'
with pyodbc.connect(conn) as db:
    cur=db.cursor();cur.fast_executemany=True
    for table in tables:
        with (root/f'{table}.csv').open(newline='',encoding='utf-8') as f:
            reader=csv.reader(f); headers=next(reader)
            placeholders=','.join('?' for _ in headers)
            columns=','.join('['+h+']' for h in headers)
            sql=f'INSERT INTO dbo.[{table}] ({columns}) VALUES ({placeholders})'
            batch=[]; count=0
            for row in reader:
                batch.append([None if v=='' else v for v in row])
                if len(batch)>=1000:
                    cur.executemany(sql,batch);count+=len(batch);batch=[]
            if batch:cur.executemany(sql,batch);count+=len(batch)
        db.commit();print(table,count)
print('Import complete. Run 02_quality_checks.sql, then 03_detect_alerts.sql.')
