with duplicate
as (
   select
       *
      ,rn = row_number() over (partition by ErpClassLevel3, ScmTypeId order by LastUpdate)
   from
       hierarchy.TypeHierarchyFlatCombined
   )
select * from duplicate where rn > 1
--delete from duplicate where rn > 1

/*
select top (100) * from [authorization].RoleUser
*/

select rows
from sys.partitions with (nolock)
where index_id in (0, 1) and object_id = object_id(N'hierarchy.TypeHierarchyFlatCombined')