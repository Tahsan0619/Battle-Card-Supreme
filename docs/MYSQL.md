# XAMPP MySQL / MariaDB recovery

Battle Card Supreme uses XAMPP MariaDB at `C:\xampp\mysql`.

## Quick start after a crash

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_mysql.ps1
```

Then:

```bash
cd api
php artisan migrate --seed
php artisan serve
```

## What usually broke it

1. Stale `C:\xampp\mysql\data\mysql.pid` after a hard kill  
2. Tiny `innodb_buffer_pool_size` / tiny `max_allowed_packet` under load  
3. XAMPP Control starting mysqld without keeping the process healthy  

## Hardening applied

In `C:\xampp\mysql\bin\my.ini`:

- `key_buffer_size=16M` (full option name)  
- `max_allowed_packet=64M`  
- `innodb_buffer_pool_size=128M`  
- `bind-address=127.0.0.1`  
- `skip-name-resolve`  

Do **not** casually change `innodb_log_file_size` on an existing datadir.

## App database

- Database: `battle_card_supreme`  
- User: `root` (XAMPP default empty password)  
- Laravel `.env` uses `DB_CONNECTION=mysql`  

## Logs

`C:\xampp\mysql\data\mysql_error.log`
