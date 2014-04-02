#!/usr/bin/env bash

build_path=$(dirname "$0")
tmp_file="$build_path/.var.tmp"

source $build_path/functions.sh

#parse_yaml $build_path/config.yml
eval $(parse_yaml $build_path/config.yml)

# Pass all arguments to drush
while [ $# -gt 0 ]; do
  drush_flags="$drush_flags $1"
  shift
done
drush="drush $drush_flags"

if [ $build_gauge = 1 ]; then
  {
    for ((i = 0 ; i <= 100 ; i+=30)); do
      sleep 1s
      echo $i
    done
  } | whiptail --title "$build_title" --gauge "\nPreparing installation..." 8 50 0
fi

if [ $build_install_refdb != 1 ] && [ $build_install_scratch != 1 ]; then
  stmsg ok "Either build_install_refdb or build_install_scartch must be set to 1."
  stmsg ok "Please check and configure your config.rb file correctly."
  stmsg aborted "Installation has been aborted."
  exit
fi

whiptail --title "$build_title" --menu "Installation method:" 15 60 5 \
  "AUTO" " - Automated build. (default)" \
  "MANUAL" " - Manual build." 2>$tmp_file
exitstatus=$?
if [ $exitstatus = 0 ]; then
  build_method=$(cat $tmp_file)
  > $tmp_file
else
  stmsg aborted "Installation has been aborted."
  exit
fi

if [ $build_method = "MANUAL" ]; then
  whiptail --title "$build_title" --checklist "Mark items to manually configure." 15 60 5 --separate-output \
  "build_env" "$build_env" 1 \
  "site_profile" "$site_profile" 1 \
  "site_account_mail" "$site_account_mail" 0 \
  "site_account_name" "$site_account_name" 0 \
  "site_account_pass" "$site_account_pass" 0 \
  "site_clean_url" "$site_clean_url" 0 \
  "site_db_prefix" "$site_db_prefix" 0 \
  "site_db_host" "$site_db_host" 0 \
  "site_db_su" "$site_db_su" 0 \
  "site_db_su_pw" "$site_db_su_pw" 0 \
  "site_mail" "$site_mail" 0 \
  "site_name" "$site_name" 0 \
  "site_subdir" "$site_subdir" 0 \
  "site_theme" "$site_theme" 0 2>$tmp_file

  build_method_manual=$(sed ':a;N;$!ba;s/\n/ /g' $tmp_file)
  > $tmp_file

  if [[ -z "$build_method_manual" ]]; then
    stmsg ok "None has been marked, or process has been cancelled."
    stmsg aborted "Installation has been aborted."
    exit
  fi
elif [ $build_method = "AUTO" ]; then
  build_method_manual="."
fi

if [[ "$build_method_manual" == *"build_env"* ]]; then
  whiptail --title "$build_title" --menu "Build environment:" 15 60 5 \
    "local" " - Local environment" \
    "production" " - Production environment, server" 2>$tmp_file
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    build_env=$(cat $tmp_file)
    > $tmp_file
    stmsg ok "build_env has been set to $build_env"
  else
    stmsg aborted "Installation has been aborted."
    exit
  fi
fi

bs=`echo \\`
if [[ "$build_method_manual" == *"site_profile"* ]]; then
  cd profiles
  site_profile_options=$(ls -d *)
  cd ..
  site_profile_options_i=$(echo $site_profile_options | wc --words)
  temp=$(i=0
  while [ $i -lt $site_profile_options_i ]; do
    let ii=i+1
    echo $(echo $site_profile_options | cut -f $ii -d " ") " - "
    let i=i+1
  done)  
  echo $temp | whiptail --title "$build_title" --menu "Build installation profile:" 15 60 5 $bs$(cat /dev/stdin) 2>$tmp_file
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    site_profile=$(cat $tmp_file)
    > $tmp_file
    stmsg ok "site_profile has been set to $site_profile"
  else
    stmsg aborted "Installation has been aborted."
    exit
  fi
fi

if [[ "$build_method_manual" == *"site_account_mail"* ]]; then
  site_account_mail_input=$(whiptail --title "$build_title" --inputbox "site_account_mail" 8 78 "$site_account_mail" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_account_mail = $site_account_mail_input ]; then
      stmsg ok "Identical changes made with site_account_mail: $site_account_mail"
    else
      site_account_mail=$site_account_mail_input
      stmsg ok "site_account_mail has been changed to: $site_account_mail_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_account_mail: $site_account_mail"
  fi
fi

if [[ "$build_method_manual" == *"site_account_name"* ]]; then
  site_account_name_input=$(whiptail --title "$build_title" --inputbox "site_account_name" 8 78 "$site_account_name" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_account_name = $site_account_name_input ]; then
      stmsg ok "Identical changes made with site_account_name: $site_account_name"
    else
      site_account_name=$site_account_name_input
      stmsg ok "site_account_name has been changed to: $site_account_name_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_account_name: $site_account_name"
  fi
fi

# this should be changed to a password prompt
if [[ "$build_method_manual" == *"site_account_pass"* ]]; then
  site_account_pass_input=$(whiptail --title "$build_title" --inputbox "site_account_pass" 8 78 "$site_account_pass" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_account_pass = $site_account_pass_input ]; then
      stmsg ok "Identical changes made with site_account_pass: $site_account_pass"
    else
      site_account_pass=$site_account_pass_input
      stmsg ok "site_account_pass has been changed to: $site_account_pass_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_account_pass: $site_account_pass"
  fi
fi

if [[ "$build_method_manual" == *"site_clean_url"* ]]; then
  site_clean_url_input=$(whiptail --title "$build_title" --inputbox "site_clean_url" 8 78 "$site_clean_url" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_clean_url = $site_clean_url_input ]; then
      stmsg ok "Identical changes made with site_clean_url: $site_clean_url"
    else
      site_clean_url=$site_clean_url_input
      stmsg ok "site_clean_url has been changed to: $site_clean_url_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_clean_url: $site_clean_url"
  fi
fi

if [[ "$build_method_manual" == *"site_db_prefix"* ]]; then
  site_db_prefix_input=$(whiptail --title "$build_title" --inputbox "site_db_prefix" 8 78 "$site_db_prefix" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_db_prefix = $site_db_prefix_input ]; then
      stmsg ok "Identical changes made with site_db_prefix: $site_db_prefix"
    else
      site_db_prefix=$site_db_prefix_input
      stmsg ok "site_db_prefix has been changed to: $site_db_prefix_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_db_prefix: $site_db_prefix"
  fi
fi

if [[ "$build_method_manual" == *"site_db_host"* ]]; then
  site_db_host_input=$(whiptail --title "$build_title" --inputbox "site_db_host" 8 78 "$site_db_host" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_db_host = $site_db_host_input ]; then
      stmsg ok "Identical changes made with site_db_host: $site_db_host"
    else
      site_db_host=$site_db_host_input
      stmsg ok "site_db_host has been changed to: $site_db_host_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_db_host: $site_db_host"
  fi
fi

if [[ "$build_method_manual" == *"site_db_su"* ]]; then
  site_db_su_input=$(whiptail --title "$build_title" --inputbox "site_db_su" 8 78 "$site_db_su" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_db_su = $site_db_su_input ]; then
      stmsg ok "Identical changes made with site_db_su: $site_db_su"
    else
      site_db_su=$site_db_su_input
      stmsg ok "site_db_su has been changed to: $site_db_su_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_db_su: $site_db_su"
  fi
fi

if [[ "$build_method_manual" == *"site_db_su_pw"* ]]; then
  site_db_su_pw_input=$(whiptail --title "$build_title" --inputbox "site_db_su_pw" 8 78 "$site_db_su_pw" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_db_su_pw = $site_db_su_pw_input ]; then
      stmsg ok "Identical changes made with site_db_su_pw: $site_db_su_pw"
    else
      site_db_su_pw=$site_db_su_pw_input
      stmsg ok "site_db_su_pw has been changed to: $site_db_su_pw_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_db_su_pw: $site_db_su_pw"
  fi
fi

if [[ "$build_method_manual" == *"site_mail"* ]]; then
  site_mail_input=$(whiptail --title "$build_title" --inputbox "site_mail" 8 78 "$site_mail" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_mail = $site_mail_input ]; then
      stmsg ok "Identical changes made with site_mail: $site_mail"
    else
      site_mail=$site_mail_input
      stmsg ok "site_mail has been changed to: $site_mail_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_mail: $site_mail"
  fi
fi

if [[ "$build_method_manual" == *"site_name"* ]]; then
  site_name_input=$(whiptail --title "$build_title" --inputbox "site_name" 8 78 "$site_name" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_name = $site_name_input ]; then
      stmsg ok "Identical changes made with site_name: $site_name"
    else
      site_name=$site_name_input
      stmsg ok "site_mail has been changed to: $site_name_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_name: $site_name"
  fi
fi

if [[ "$build_method_manual" == *"site_subdir"* ]]; then
  site_subdir_input=$(whiptail --title "$build_title" --inputbox "site_subdir" 8 78 "$site_subdir" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_subdir = $site_subdir_input ]; then
      stmsg ok "Identical changes made with site_subdir: $site_subdir"
    else
      site_subdir=$site_subdir_input
      stmsg ok "site_mail has been changed to: $site_subdir_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_subdir: $site_subdir"
  fi
fi

if [[ "$build_method_manual" == *"site_theme"* ]]; then
  site_theme_input=$(whiptail --title "$build_title" --inputbox "site_theme" 8 78 "$site_theme" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    if [ $site_theme = $site_theme_input ]; then
      stmsg ok "Identical changes made with site_theme: $site_theme"
    else
      site_theme=$site_theme_input
      stmsg ok "site_mail has been changed to: $site_theme_input"
    fi
  else
    stmsg ok "(default) No changes has been made with site_theme: $site_theme"
  fi
fi


# INSTALLATION START

if [ $build_install_refdb = 1 ]; then
  $drush sql-drop -yq
  stmsg success "The database has been dropped before importation."
  if [[ -f $build_path/refdbs/base--$build_env.sql ]]; then
    $drush sqlc -yq < $build_path/refdbs/base--$build_env.sql
    stmsg ok "An environment $build_env's refdb has been imported."
  elif [[ -f $build_path/refdbs/base.sql ]]; then
    $drush sqlc -yq < $build_path/refdbs/base.sql
    stmsg ok "The environment $build_env's refdb cannot be found. Skipping."
    stmsg ok "The generic refdb has been used and imported."
  else
    stmsg ok "The environment $build_env's refdb cannot be found. Skipping."
    stmsg aborted "The generic refdb cannot be found."
    stmsg aborted "Installation has been aborted."
  fi
elif [ $build_install_scratch = 1 ] && [ $build_install_refdb != 1 ]; then
  $drush si -yiq $site_profile --account-name=$site_account_name --account-pass=$site_account_pass --db-url=mysql://$site_db_su:$site_db_su_pw@$site_db_host/$site_db_name
  stmsg success "The site has been installed from scatch."
fi

stmsg ok "Enabling all modules that are needed."
$drush en $(cat $build_path/mods_enabled | tr '\n' ' ') -y

stmsg ok "Disabling all modules that are not needed."
$drush dis $(cat $build_path/mods_purge | tr '\n' ' ') -y

stmsg ok "Uninstalling all modules that are disabled."
$drush pm-uninstall $(cat $build_path/mods_purge | tr '\n' ' ') -y

stmsg ok "Enabling default theme."
$drush en $site_theme -yq
stmsg success "The default theme has been enabled: $site_theme"

stmsg ok "Clearing all caches."
$drush cc all -yq
stmsg success "All caches has been cleared."

stmsg ok "Reverting all features."
$drush fra -y

#stmsg ok "Running any updates."
#$drush updb -y

stmsg ok "Importing content."
stmsg success "All content has been imported."
$drush scr $build_path/scripts/feeds-import.php

stmsg ok "Clearing all caches."
$drush cc all -yq
stmsg success "All caches has been cleared."

stmsg ok "Reverting all features."
$drush fra -y

stmsg ok "Disabling css and js caching."
$drush vset -yq preprocess_css 0
$drush vset -yq preprocess_js 0
stmsg success "CSS and JS caching has been disabled."

stmsg ok "Rebuilding permissions."
$drush php-eval 'node_access_rebuild();' -q
stmsg success "Permissions has been rebuilt."

stmsg ok "Clearing all caches for the last time."
$drush cc all -yq
stmsg success "All caches has been cleared."

stmsg success "Installation is complete."
