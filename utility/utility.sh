#!/bin/sh

# logging function 
log() {
  local level=$1
  shift
  if [[ $VERBOSE -ge $level ]]; then
    echo -e "$@"
  fi
}

# timer function
timer() {
    local func_name=$1; shift;

    echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t$func_name Start"
    local start_time=$(date +%s);
    $func_name "$@";

    local end_time=$(date +%s);
    echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t$func_name End"
    
    local elapsed_time=$(TZ=UTC0 printf '%(%H:%M:%S)T\n' $((end_time-$start_time)))
    echo -e "Elapsed Time $elapsed_time"
}

check_and_create_dir() {
  local base_dir=$1
  local sub_dir=$2
  
  if [ ! -d "$base_dir/$sub_dir" ]; then
    log 1 "The '$sub_dir' directory does not exist in '$base_dir'. Creating it..."
    mkdir -p "$base_dir/$sub_dir"
    if [ $? -ne 0 ]; then
      log 0 "Error: Failed to create the directory '$base_dir/$sub_dir'."
      log 0 ""
      exit 1
    fi
  else
    log 1 "Checked the existence of $base_dir/$sub_dir"
  fi
}

check_essential_option() {
  local option=$1
  local variable=$2

  if [ -z "$variable" ]; then
  log 0 "Error: --${option} option is required."
  log 0 ""
  usage
  exit 1
fi
}

check_file_existence() {
  local file_name=$1
  local file_path=$2

  if [ ! -f "$file_path" ]; then
  log 0 "Error: The ${file_name} file '$file_path' does not exist."
  log 0 ""
  exit 1
  fi  
}

check_dir_existence() {
  local dir_name=$1
  local dir_path=$2

  if [ ! -d "$dir_path" ]; then
  log 0 "Error: The ${dir_name} directory '$dir_path' does not exist."
  log 0 ""
  exit 1
  fi  
}

check_variables_set() {
  local unset_vars=()  

  for var_name in "$@"; do
    # Check if the variable is declared and set
    if ! declare -p "$var_name" &>/dev/null; then
      unset_vars+=("$var_name")
    else
      # Variable is declared; check if it's empty
      if [[ -z "${!var_name}" ]]; then
        unset_vars+=("$var_name")  # Add to unset_vars array
      fi
    fi
  done

  # If there are unset variables, log the error and exit
  if [[ ${#unset_vars[@]} -ne 0 ]]; then
    log 0 "[Error]: One or more variables are not set or declared."
    for var in "${unset_vars[@]}"; do
      log 0 "$var: UNSET"
    done
    log 0 ""
    exit 1  # Exit with error status
  fi
}

check_bai_existence() {
  local file_name=$1
  parent_dir=$(dirname "${file_name}")
  base_name=$(basename ${file_name} .bam )
  if [ ! -f "$parent_dir/${base_name}.bai" ]; then
    conda activate $SAMTOOLS_ENV
    log 1 "Creating index file for ${base_name}.bam"
    samtools index $file_name
    mv ${parent_dir}/${base_name}.bam.bai ${parent_dir}/${base_name}.bai 
    log 1 "Done indexing"
    log 1 ""
    conda deactivate
  fi  
}

cleanup() {
  check_variables_set LOCKFILE
  if [[ -e $LOCKFILE ]]; then
    exec 200<> $LOCKFILE

    flock -x 200

    REFCOUNT=$(<$LOCKFILE)
    ((REFCOUNT--))

    echo "${REFCOUNT}" > $LOCKFILE

    if [[$REFCOUNT -eq 0 ]]; then
      rm -f $LOCKFILE
    fi

    flock -u 200
  fi

  exit 
}