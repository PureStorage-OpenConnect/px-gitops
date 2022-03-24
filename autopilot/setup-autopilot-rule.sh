#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S')";
  PX_LOG_FILE="./debug.log";
  . config-vars
  PVC_MATCH_LABEL="type=git-server"
  NAMESPACE_MATCH_LABEL="type=git-server"
printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"
printf "Executing: ${0} \n"  >> "${PX_LOG_FILE}"
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
    echo -e "\nUsage:\n    ${0}\n" >&2
    exit 1
  }

printf "Setting up Autopilot rule (Global) for git servers.\n" | tee -a "${PX_LOG_FILE}"

 ##Check: connectivity.
   printf "Checking connectivity to the cluster by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
   kubectl get ns kube-system >> "${PX_LOG_FILE}"
   printf "Successful\n" >> "${PX_LOG_FILE}"

##Creating Autopilot rule manifest.
  PX_PVC_MATCH_LABELS_NAME="$(echo "${PVC_MATCH_LABEL}" | cut -f1 -d'=')"
  PX_PVC_MATCH_LABELS_VALUE="$(echo "${PVC_MATCH_LABEL}" | cut -f2 -d'=')"
  PX_NAMESPACE_MATCH_LABELS_NAME="$(echo "${NAMESPACE_MATCH_LABEL}" | cut -f1 -d'=')"
  PX_NAMESPACE_MATCH_LABELS_VALUE="$(echo "${NAMESPACE_MATCH_LABEL}" | cut -f2 -d'=')"
  PX_VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION="${VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION}"
  PX_SCALE_PERCENTAGE="${SCALE_PERCENTAGE}"
  PX_VOLUME_MAX_SIZE="${VOLUME_MAX_SIZE}"
  PX_MANIFEST_FILES_DIR="./manifest-files"
  mkdir -p "${PX_MANIFEST_FILES_DIR}"
  PX_AUTOPILOT_RULE_NAME="nslbl-${PX_NAMESPACE_MATCH_LABELS_NAME}-${PX_NAMESPACE_MATCH_LABELS_VALUE}-pvclbl-${PX_PVC_MATCH_LABELS_NAME}-${PX_PVC_MATCH_LABELS_VALUE}-limit-${PX_VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION}-scale-${PX_SCALE_PERCENTAGE}"
  PX_AUTOPILOT_RULE_MANIFEST_FILE="${PX_MANIFEST_FILES_DIR}/${PX_AUTOPILOT_RULE_NAME}.yml"

  printf "Creating Autopilot rule manifest: " >> "${PX_LOG_FILE}"
  cat ./templates/autopilot-rule.yml | \
      sed "s,<PX_AUTOPILOT_RULE_NAME>,${PX_AUTOPILOT_RULE_NAME},g" | \
      sed "s,<PX_PVC_MATCH_LABELS_NAME>,${PX_PVC_MATCH_LABELS_NAME},g" | \
      sed "s,<PX_PVC_MATCH_LABELS_VALUE>,${PX_PVC_MATCH_LABELS_VALUE},g" | \
      sed "s,<PX_NAMESPACE_MATCH_LABELS_NAME>,${PX_NAMESPACE_MATCH_LABELS_NAME},g" | \
      sed "s,<PX_NAMESPACE_MATCH_LABELS_VALUE>,${PX_NAMESPACE_MATCH_LABELS_VALUE},g" | \
      sed "s,<PX_VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION>,${PX_VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION},g" | \
      sed "s,<PX_SCALE_PERCENTAGE>,${PX_SCALE_PERCENTAGE},g" | \
      sed "s,<PX_VOLUME_MAX_SIZE>,${PX_VOLUME_MAX_SIZE},g" > \
      "${PX_AUTOPILOT_RULE_MANIFEST_FILE}"
  printf "Done! Saved at: ${PX_AUTOPILOT_RULE_MANIFEST_FILE}\n" >> "${PX_LOG_FILE}"

  printf "Apply Autopilot rule manifest: " >> "${PX_LOG_FILE}"
  kubectl apply -f ${PX_AUTOPILOT_RULE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  printf "Done!\n" >> "${PX_LOG_FILE}"
  sleep 2
  printf "Describe Autopilot rule:\n" >> "${PX_LOG_FILE}"
  kubectl describe -f ${PX_AUTOPILOT_RULE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  printf "Autopilot rule has been set up with the name: ${PX_AUTOPILOT_RULE_NAME}\n\n" | tee -a "${PX_LOG_FILE}"

