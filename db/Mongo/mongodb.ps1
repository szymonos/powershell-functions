# switch to super user
sudo su
# 1. disable authorization in mongod.conf
nano /etc/mongod.conf
cat /etc/mongod.conf

# security:

#    authorization: disabled
# 2. restart mongo
service mongod stop
service mongod start

# .3 login to mongo
mongo localhost:27017/Admin

# 4. create administrator account
use admin
db.createUser(
  {
    user: "mdbdev_adm",
    pwd: "password",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  }
)

# add permissions to restore and backup
db.updateUser( "mdbdev_adm",
  { roles : [
    { role : "restore", db : "admin"  },
    { role : "backup", db : "admin"  }
    ]
  }
)

# Add root permissions to user
db.grantRolesToUser( 'mdbdev_adm', [{ role: 'root', db: 'admin' }])
exit
# 5. enable authorization
# security:
#    authorization: enabled

# restart mongodb service
service mongod stop
service mongod start

# copy mongo database
cd "C:\Program Files\MongoDB\Server\3.6\bin"
.\mongodump --host 10.10.10.37 --db test --archive | .\mongorestore --username mdbdev_adm --password pass --host 52.137.55.40 --archive
.\mongodump.exe --host 10.10.10.37 --db test --archive testdump

.\mongodump --host 10.10.10.37 --db SearchRequestLog --archive=mongotest.agz --gzip

.\mongorestore --gzip --archive=mongotest.agz --username mdbdev_adm --password pass --host 52.137.55.40
.\mongorestore --gzip --archive=C:\temp\test.agz --username mdbdev_adm --password pass --host 52.137.55.40

.\mongodump --host=10.10.10.37 --db=SearchRequestLog --collection=SearchClicks --archive=C:\temp\SearchClicks.agz --gzip
.\mongorestore --host=also-searchservice-cosmos-dev.mongo.cosmos.azure.com:10255 --archive=C:\temp\SearchClicks.agz --gzip --username=also-searchservice-cosmos-dev --password=pass --ssl --sslAllowInvalidCertificates
