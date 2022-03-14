#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S')";
  PX_LOG_FILE="./debug.log";

printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"

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
    echo -e "\nUsage:\n    ${0} namespace-you-want-run-the-operaton-on\n" >&2
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

printf "Started process to fillup the volumes. Please wait until it completes.\n" | tee -a "${PX_LOG_FILE}"
##Check: Command-line parameter must passed.
  printf "Checking: Command-line parameter must passed: " >> "${PX_LOG_FILE}"
  if [[ -z "${1+x}" ]]; then
    echo -e "\n\nCommand-line parameter missing." | tee -a "${PX_LOG_FILE}"
    fun_howtouse
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

  PX_NAMESPACE="$1"

##Check: connectivity.
  printf "Checking connectivity to the cluster by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system >> "${PX_LOG_FILE}"
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Check: The namespace must exist and it must be a valid git-repo
  printf "Checking: Namespace must exist and must be a valid git-repo: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE} -o custom-columns=":metadata.labels.type" --no-headers  2>> "${PX_LOG_FILE}" | \
      grep -x "git-server" > /dev/null 2>&1 || \
      { echo -e "\nError: Repository namespace \"${PX_NAMESPACE}\" does not exist on the cluster OR it is not a valid git server namespace.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Valid\n" >> "${PX_LOG_FILE}" 
  fun_progress

##Fillup the pvc.
  printf "Finding a pod from the namespace: " >> "${PX_LOG_FILE}"
  PX_GIT_POD_NAME="$(kubectl get pods -n "${PX_NAMESPACE}" -o jsonpath={.items[0].metadata.name} 2>> "${PX_LOG_FILE}" || true)"
  fun_progress
  if [[ "${PX_GIT_POD_NAME}" != "" ]]; then
    printf "Found pod '${PX_GIT_POD_NAME}'\n" >> "${PX_LOG_FILE}"
    printf "Started filling the pvc: " >> "${PX_LOG_FILE}"
    kubectl exec --tty --stdin "${PX_GIT_POD_NAME}" -n "${PX_NAMESPACE}" -- bash -c 'dd if=/dev/urandom of="$(df --output=target | grep /home/git/repos/| head -1)/data-file" bs=10M count=700' 2>> "${PX_LOG_FILE}"
    fun_progress
    printf "Successful\n" >> "${PX_LOG_FILE}"
  else
    printf "Unable to find a pod to run the script.\n" | tee -a "${PX_LOG_FILE}"
    exit
  fi
