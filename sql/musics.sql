drop view musics;
create view musics as
select
    `id`, `text_id`, `number`, `title`, `sortkey`,
    `std_lv`, `hrd_lv`, `mas_lv`, `std_notes`, `hrd_notes`, `mas_notes`,
    `std_locked`, `hrd_locked`, `mas_locked`, `limited`,
    (case when exists (
        select 1 from `rptargets` where ((`_musics`.`id` = `rptargets`.`music_id`) and (`rptargets`.`span_s` <= now()) and (`rptargets`.`span_e` > now()))) then 1 else 0 end) AS `monthly`,
    `created_at`, `updated_at`
from `_musics` where `display` = 1;
