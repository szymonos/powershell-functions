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
    { role : "restore", db : "admin" },
    { role : "backup", db : "admin" }
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
