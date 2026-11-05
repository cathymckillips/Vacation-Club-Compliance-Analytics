"""Generate reproducible, entirely synthetic vacation club compliance datasets. Python 3.10+; standard library only."""
import argparse, csv, random
from pathlib import Path
from datetime import date, timedelta

P = Path(__file__).resolve().parents[1] / '01_data'
AS_OF = date(2026, 10, 31)

def write(name, cols, rows):
    P.mkdir(parents=True, exist_ok=True)
    with (P / f'{name}.csv').open('w', newline='', encoding='utf-8') as f:
        w=csv.writer(f); w.writerow(cols); w.writerows(rows)
    print(f'{name}: {len(rows):,} rows')

def main(n, bookings, seed):
    rng=random.Random(seed)
    resorts=[(i, f'Resort {i:03}', ['Florida','California','Hawaii','Nevada','South Carolina'][i%5]) for i in range(1,51)]
    write('DimResort',['ResortID','ResortName','Region'],resorts)
    members=[]
    for i in range(1,n+1):
        tier=rng.choices(['Standard','Silver','Gold','Platinum'],[45,30,20,5])[0]
        members.append((i,f'MBR-{i:06}',tier,(date(2020,1,1)+timedelta(days=rng.randint(0,2100))).isoformat(),'Active' if rng.random()<.94 else 'Inactive'))
    write('DimMember',['MemberID','MemberCode','MembershipTier','JoinDate','MemberStatus'],members)
    # Intentionally concentrated activity for a small cohort; these are leads for review, not established misconduct.
    concentrated=set(range(1,max(15,n//100)+1))
    reservations=[]
    for i in range(1,bookings+1):
        member=rng.choice(tuple(concentrated)) if rng.random()<.13 else rng.randint(1,n)
        bd=AS_OF-timedelta(days=rng.randint(0,364))
        stay=bd+timedelta(days=rng.randint(3,110))
        status=rng.choices(['Confirmed','Completed','Canceled'],[35,45,20])[0]
        guest=f'GUEST-{rng.randint(1,n*2):06}'
        if member in concentrated and rng.random()<.42: guest=f'SHARED-{member%7:03}'
        pts=rng.choice([800,1200,1800,2500,4000,6000])
        reservations.append((i,member,rng.randint(1,50),bd.isoformat(),stay.isoformat(),(stay+timedelta(days=rng.randint(2,7))).isoformat(),status,pts,guest,1 if guest.startswith('SHARED') else 0))
    write('FactReservation',['ReservationID','MemberID','ResortID','BookingDate','CheckInDate','CheckOutDate','BookingStatus','PointsUsed','GuestToken','ThirdPartyGuestFlag'],reservations)
    ledger=[]; tx=0
    for m in range(1,n+1):
        tx+=1; ledger.append((tx,m,(AS_OF-timedelta(days=350)).isoformat(),'AnnualAllocation',rng.choice([12000,18000,24000,36000]),'SYSTEM',1))
    for i in range(n*3):
        m=rng.randint(1,n); dt=AS_OF-timedelta(days=rng.randint(0,345)); kind=rng.choices(['Redemption','Adjustment','TransferIn','TransferOut'],[65,20,8,7])[0]
        amt= -rng.choice([800,1200,1800,2500,4000,6000]) if kind in ('Redemption','TransferOut') else rng.choice([1000,3000,6000,12000])
        if kind=='Adjustment' and rng.random()<.12: amt=15000
        approved=0 if kind=='Adjustment' and rng.random()<.16 else 1
        tx+=1; ledger.append((tx,m,dt.isoformat(),kind,amt,'AGENT-'+str(rng.randint(1,80)).zfill(3),approved))
    write('FactPointsLedger',['TransactionID','MemberID','TransactionDate','TransactionType','PointsDelta','ActorID','ApprovedFlag'],ledger)
    interactions=[]
    for i in range(1,n*2+1):
        m=rng.randint(1,n); dt=AS_OF-timedelta(days=rng.randint(0,364)); action=rng.choices(['Inquiry','BookingHelp','AccountOverride','PointsAdjustment'],[50,25,15,10])[0]
        interactions.append((i,m,dt.isoformat(),f'AGENT-{rng.randint(1,80):03}',action,0 if action=='AccountOverride' and rng.random()<.13 else 1))
    write('FactContactCenter',['InteractionID','MemberID','InteractionDate','AgentID','ActionType','ApprovedFlag'],interactions)
    rules=[('CR001','High booking frequency','More than 8 confirmed/completed bookings in rolling 30 days','Medium',8),('CR002','High cancellation rate','At least 5 bookings and >40% canceled in rolling 90 days','Medium',40),('CR003','Negative points balance','Net points ledger balance below zero','High',0),('CR004','Shared third-party guest','Same shared guest token booked by 3+ distinct accounts','Review',3),('CR005','Unapproved large adjustment','Unapproved positive points adjustment >10000','High',10000),('CR006','Unapproved account override','Contact center account override lacking approval','High',0)]
    write('DimComplianceRule',['RuleID','RuleName','RuleDescription','Severity','ThresholdValue'],rules)
    print('All records are synthetic. Seed:',seed,'As-of date:',AS_OF)

if __name__=='__main__':
    a=argparse.ArgumentParser(); a.add_argument('--members',type=int,default=3000); a.add_argument('--bookings',type=int,default=18000); a.add_argument('--seed',type=int,default=42); x=a.parse_args()
    main(x.members,x.bookings,x.seed)
