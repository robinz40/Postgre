#!/bin/bash
source /etc/postgre-backup.conf

function backup(){
  #echo $backup_dir
  # archivage de la bdd
  mysqldump -h $host --user=$databaselogin --password=$databasepassword --all-databases > /tmp/web_app.sql
  tar --bzip2 -cvf $backup_dir/sqldump$(date "+-%Y-%m-%d-%H-%M").tar.bz2 /tmp/web_app.sql
  rm /tmp/web_app.sql

  # retention date
  find $backup_dir/* -mtime +$number_of_day_to_keep -exec /bin/rm -f {} \;

  # retention number
  let "number_of_file_to_keep++"
  if [ $(ls -t $backup_dir/sqldump-* | tail -n +$number_of_file_to_keep) ]
  then
    rm $(ls -t $backup_dir/sqldump-* | tail -n +$number_of_file_to_keep);
  else
    echo ""
  fi
}

# restauration de la bdd
function restore(){
  mysql -h $host --user=root --password=web_app < $(tar -xvf backup/$1)
}

# liste des sauvegarde
function list(){
  ls $backup_dir/
}

function usage(){
  echo "Welcome to help !"
  echo "Use sqldump --list to list every files in the backup directory"
  echo "Use sqldump --backup to backup your database in the backup directory.
                This command will also remove backups older than what you wrote
                in your configuration file."
  echo "Use sqldump --restore 'file' to restore 'file' to your database.
                The file should be in .tar.bz2 format, and only contain the
                web_app.sql file, it should also be in your backup directory."
}

OPTS=$( getopt -o h,l,b,r -l help,backup,list,restore: -- "$@" )
if [ $? != 0 ]
then
  exit 1
fi

eval set -- "$OPTS"

while true ; do
  case "$1" in
    -h) usage;
        exit 0;;
    -l) list;
        shift;;
    -b) backup;
        shift;;
    --help) usage;
            exit 0;;
    --backup) backup;
              shift;;
    --list) list;
            shift;;
    --restore) restore $2;
               shift 2;;
    --) shift; break;;
  esac
done

exit 0
