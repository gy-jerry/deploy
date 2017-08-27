# created on Apr 10th, 2017


use admin
# 数据库管理员
db.createUser(
  {
    user: "SuperAdmin",
    pwd: "qaz@163.com",
    roles: [ { role: "readWriteAnyDatabase", db: "admin" },{ role: "dbAdminAnyDatabase", db: "admin" },{ role: "clusterAdmin", db: "admin" } ]
  }
)
# 用户管理员
db.createUser(
  {
    user: "UserAdmin",
    pwd: "wsx@163.com",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  }
)


use cdmis
# cdmis数据库用户管理员
db.createUser(
  {
    user: "UserAdmin",
    pwd: "wsx@163.com",
    roles: [ { role: "userAdmin", db: "cdmis" } ]
  }
)
# cdmis数据库用户
db.createUser(
  {
    user: "rest",
    pwd: "zjubme319",
    roles: [ { role: "readWrite", db: "cdmis" } ]
  }
)

db.changeUserPassword('rest','zjubme319')




