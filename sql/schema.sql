
create table if not exists users (
    id  bigint unsigned not null auto_increment,
    username  varchar(64) not null,
    password  varchar(255) not null,
    best_score int unsigned not null default 0,
    created_time timestamp not null default current_timestamp,
    primary key (id),
    unique key uk_users_username (username)
) engine = InnoDB default charset = utf8mb4 collate = utf8mb4_unicode_ci;

create table if not exists run_logs (
    id bigint unsigned not null auto_increment,
    uid bigint unsigned not null,
    general_id varchar(32) not null,  -- 武将配置id
    score int unsigned not null default 0,
    win tinyint(1) not null default 0,  -- 通过成功或失败
    created_time timestamp not null default current_timestamp,
    primary key (id),
    key idx_run_logs_uid(uid),
    constraint fk_run_logs_uid foreign key (uid) references users (id) -- uid作为外键
) engine = InnoDB default charset = utf8mb4 collate = utf8mb4_unicode_ci;
