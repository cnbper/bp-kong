# postgres

## 进入postgres

```shell
kubectl -n kong get pod -l app=postgres -o wide
kubectl -n kong get svc postgres -o wide

# 进入
kubectl exec -it -n kong postgres-0 /bin/bash
# 密码kong
psql -h localhost -U kong --password -p 5432 kong

## 测试命令
select version();

select * from pg_tables;

select relname as tabname, cast(obj_description(relfilenode,'pg_class') as varchar) as comment
from pg_class c
where relkind = 'r' and relname not like 'pg_%' and relname not like 'sql_%'
order by relname;

select col_description(a.attrelid,a.attnum) as comment,format_type(a.atttypid,a.atttypmod) as type,a.attname as name, a.attnotnull as notnull
from pg_class as c, pg_attribute as a
where c.relname = 'routes' and a.attrelid = c.oid and a.attnum>0
```