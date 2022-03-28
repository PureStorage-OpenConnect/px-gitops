#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S')";
  PX_LOG_FILE="./debug.log";

printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"

printf "Collecting requrired imformation...\n" | tee -a "${PX_LOG_FILE}"
##Check utilities
  printf "Checking utilities:\n" >> "${PX_LOG_FILE}"
  for util in kubectl sed; do
    if ! which $util  2>&1 >> "${PX_LOG_FILE}" ; then
      echo "ERROR: $util binary not found in your PATH veriable. Aborting."| tee -a "${PX_LOG_FILE}"
      exit 1
    fi
  done
  printf "All utililities are available\n" >> "${PX_LOG_FILE}"

##Help text
  fun_howtouse() {
    echo -e "\nUsage:\n    ${0}  [namespace-you-want-run-the-operaton-on]  [size-of-the-data-to-be-written-in-GB]\n" >&2
    exit 1
  }

##Display Progress
  vPROGRESS=" = >"
  fun_progress() {
    printf "\r${vPROGRESS}"
    vPROGRESS="$(
        if [[ "${vPROGRESS:0:1}" == "=" ]]; then
          printf " ";
        else
          printf "=";
        fi)${vPROGRESS}"
    sleep .2
  }

##Check: Command-line parameter must passed.
  printf "Checking: Command-line parameter must passed: " >> "${PX_LOG_FILE}"
  if [[ -z "${1+x}" ]] || [[ -z "${2+x}" ]]; then
    echo -e "\n\nCaution: Command-line parameter missing." | tee -a "${PX_LOG_FILE}"
    fun_howtouse
  fi

  PX_DATA_SIZE="$(echo ${2}|tr -dc '0-9')"
  if [[ "${PX_DATA_SIZE}" != "${2}" ]] ; then
    echo -e "\n\nCaution: 2nd parameter must be an integer." | tee -a "${PX_LOG_FILE}"
    fun_howtouse
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"

  PX_NAMESPACE="$1"

##Check: connectivity.
  printf "Checking connectivity to the cluster by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system >> "${PX_LOG_FILE}"
  printf "Successful\n" >> "${PX_LOG_FILE}"

##Check: The namespace must exist and it must be a valid git-repo
  printf "Checking: Namespace must exist and must be a valid git-repo: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE} -o custom-columns=":metadata.labels.type" --no-headers  2>> "${PX_LOG_FILE}" | \
      grep -x "git-server" > /dev/null 2>&1 || \
      { echo -e "\nError: Repository namespace \"${PX_NAMESPACE}\" does not exist on the cluster OR it is not a valid git server namespace.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Valid\n" >> "${PX_LOG_FILE}" 

printf "Started process to fillup the volumes. Please wait until it completes.\n" | tee -a "${PX_LOG_FILE}"
##Fillup the pvc.
  printf "Finding a pod from the namespace: " >> "${PX_LOG_FILE}"
  PX_GIT_POD_NAME="$(kubectl get pods -n "${PX_NAMESPACE}" -o jsonpath={.items[0].metadata.name} 2>> "${PX_LOG_FILE}" || true)"
  fun_progress
  if [[ "${PX_GIT_POD_NAME}" != "" ]]; then
    printf "Found pod '${PX_GIT_POD_NAME}'\n" >> "${PX_LOG_FILE}"
    printf "Started filling the pvc.\n" >> "${PX_LOG_FILE}"
    while (( PX_DATA_SIZE > 0 ))
    do
      PX_DATA_FILE_NAME="data-file-$(date -u '+%Y-%m-%d-%H-%M-%S')";
      kubectl exec --tty --stdin "${PX_GIT_POD_NAME}" -n "${PX_NAMESPACE}" \
          -- bash -c 'dd if=/dev/urandom of="$(df --output=target | grep /home/git/repos/| head -1)/'${PX_DATA_FILE_NAME}'" bs=10M count=100' >> "${PX_LOG_FILE}" 2>&1
      fun_progress
      PX_DATA_SIZE=$(( PX_DATA_SIZE - 1 ))
      printf "Remaining data to be written: ${PX_DATA_SIZE}GB\n" >> "${PX_LOG_FILE}"
    done;

    printf "\nSuccessful\n"
    printf "Successful\n" >> "${PX_LOG_FILE}"
    printf "\nCurrent volume stats:\n" | tee -a "${PX_LOG_FILE}"
    kubectl exec --tty --stdin "${PX_GIT_POD_NAME}" -n "${PX_NAMESPACE}" \
          -- bash -c 'df -h --output=size,used,avail,pcent $(df --output=target | grep /home/git/repos/| head -1)' 2>> "${PX_LOG_FILE}" | tee -a "${PX_LOG_FILE}"
  else
    printf "Unable to find a pod to run the script.\n" | tee -a "${PX_LOG_FILE}"
    exit
  fi
