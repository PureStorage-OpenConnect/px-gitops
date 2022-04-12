#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S-%Z')";
  PX_LOG_FILE="./debug.log";
  PX_SVC_PORT_DST="9001"
  PX_OUTPUT_DIR="./output"
  mkdir -p ${PX_OUTPUT_DIR}
  PX_RESOURCES_LOG_FILE="${PX_OUTPUT_DIR}/resources-created_tmp"
  rm ${PX_RESOURCES_LOG_FILE} >/dev/null 2>&1 || true
printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"

##Check utililities
  printf "Checking utililities:\n" >> "${PX_LOG_FILE}"
  for util in storkctl kubectl awk sed; do
    if ! which $util  2>&1 >> "${PX_LOG_FILE}" ; then
      echo "ERROR: $util binary not found in your PATH veriable. Aborting."| tee -a "${PX_LOG_FILE}"
      exit 1
    fi
  done
  printf "All utililities are available\n" >> "${PX_LOG_FILE}"

##Help text
  howtouse() {
    echo -e "\nUsage:\n    ${0} <namespace-containing-the-repository-to-replicate-on-remote-cluster>\n" >&2
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

printf "Started setting up AsyncDR and migrating the application. This may take some time depending on the environment.\n" | tee -a "${PX_LOG_FILE}"

##Check: command-line parameter must passed.
  printf "Checking: Command-line parameter must passed: " >> "${PX_LOG_FILE}"
  if [[ -z "${1+x}" ]]; then
    echo -e "\n\nCommand-line parameter missing." | tee -a "${PX_LOG_FILE}"
    howtouse
  fi
  PX_NAMESPACE_TO_MIGRATE="$1"
  printf "Successful\n" >> "${PX_LOG_FILE}"
##Inport config variables
  vCONFIFILE=./config-vars
  source ${vCONFIFILE}

##Setting kube-configs
  printf "Checking: kube-config files must exist: " >> "${PX_LOG_FILE}"
  if [[ ! -f "${PX_KUBECONF_FILE_SOURCE_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for source cluster not found: \"${PX_KUBECONF_FILE_SOURCE_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_SOURCE_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1
  fi
  if [[ ! -f "${PX_KUBECONF_FILE_DESTINATION_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for destination cluster not found: \"${PX_KUBECONF_FILE_DESTINATION_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_DESTINATION_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n"  | tee -a "${PX_LOG_FILE}"
    exit 1
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress
  PX_KUBECONF_SRC="--kubeconfig=${PX_KUBECONF_FILE_SOURCE_CLUSTER}";
  PX_KUBECONF_DST="--kubeconfig=${PX_KUBECONF_FILE_DESTINATION_CLUSTER}";
  printf "INFO|PX_KUBECONF_SRC|${PX_KUBECONF_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}
  printf "INFO|PX_KUBECONF_DST|${PX_KUBECONF_DST}\n" >> ${PX_RESOURCES_LOG_FILE}

##Check: Connectivity.
  printf "Checking connectivity to the source and destination clusters by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system ${PX_KUBECONF_SRC} >> "${PX_LOG_FILE}" 2>&1 || { echo "\nError: Unable to connect to the source cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  fun_progress
  kubectl get ns kube-system ${PX_KUBECONF_DST} >> "${PX_LOG_FILE}" 2>&1 || { echo "\nError: Unable to connect to the destination cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  fun_progress
  printf "Successful\n" >> "${PX_LOG_FILE}"

##Validate Namespaces.
  printf "Checking: Namespace '${PX_NAMESPACE_TO_MIGRATE}' must exist and must be a valid git-repo: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE_TO_MIGRATE} -o custom-columns=":metadata.labels.type" --no-headers ${PX_KUBECONF_SRC} 2>> "${PX_LOG_FILE}" | \
      grep -x "git-server" > /dev/null 2>&1 || \
      { echo -e "\nError: The namespace \"${PX_NAMESPACE_TO_MIGRATE}\" does not exist on the source cluster OR it is not a valid repository.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}" 
  fun_progress
  printf "Checking: The standby namespace '${PX_NAMESPACE_TO_MIGRATE}' must not be existing on the destination cluster: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE_TO_MIGRATE} ${PX_KUBECONF_DST} > /dev/null 2>&1 && { printf "\n\n"; echo -e "Error: The namespace \"${PX_NAMESPACE_TO_MIGRATE}\" is already existing on the destination cluster.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress
  printf "Checking: The clone namespace must not be existing on the destination cluster: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE_TO_MIGRATE}-${PX_DST_NAMESPACE_SUFFIX} ${PX_KUBECONF_DST} > /dev/null 2>&1 && { printf "\n\n"; echo -e "Error: THe clone namespace \"${PX_NAMESPACE_TO_MIGRATE}-${PX_DST_NAMESPACE_SUFFIX}\" is already existing on the destination cluster.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress
  printf "INFO|PX_NAMESPACE_TO_MIGRATE|${PX_NAMESPACE_TO_MIGRATE}\n" >> ${PX_RESOURCES_LOG_FILE}
  printf "INFO|PX_DST_NAMESPACE_SUFFIX|${PX_DST_NAMESPACE_SUFFIX}\n" >> ${PX_RESOURCES_LOG_FILE}

##Finding portworx storage cluster namespace and pods.
  printf "Finding portworx namespace and pods on source cluster: " >> "${PX_LOG_FILE}"
  PX_NS_AND_ALL_PODS_SCR="$(kubectl ${PX_KUBECONF_SRC} get pods -l name=portworx --all-namespaces -o jsonpath="{range .items[?(@.metadata.ownerReferences[*].kind=='StorageCluster')]}{.metadata.namespace}{' '}{.metadata.name}{'\n'}{end}"||true)"
  fun_progress
  if [[ "${PX_NS_AND_ALL_PODS_SCR}" != "" ]]; then
    PX_NS_SRC="$(echo "${PX_NS_AND_ALL_PODS_SCR}"|cut -d' ' -f1|head -1)"
    PX_ALL_PODS_SRC="$(echo "${PX_NS_AND_ALL_PODS_SCR}"|cut -d' ' -f2|xargs)"
    PX_1ST_POD_SRC="$(echo "${PX_NS_AND_ALL_PODS_SCR}"|cut -d' ' -f2|head -1|xargs)"
    printf "NS: ${PX_NS_SRC}, Pods: ${PX_ALL_PODS_SRC}\n" >> "${PX_LOG_FILE}"
  else
    printf "\n"
    printf "Error: Unable to identify portworx namespace and pods on the source cluster, make sure portworx is set up and functioning.\n\n" | tee -a "${PX_LOG_FILE}";
    exit 1;
  fi
  printf "INFO|PX_NS_SRC|${PX_NS_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}
  printf "INFO|PX_ALL_PODS_SRC|${PX_ALL_PODS_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}

  printf "Finding portworx namespace and pods on destination cluster: " >> "${PX_LOG_FILE}"
  PX_NS_AND_ALL_PODS_DST="$(kubectl ${PX_KUBECONF_DST} get pods -l name=portworx --all-namespaces -o jsonpath="{range .items[?(@.metadata.ownerReferences[*].kind=='StorageCluster')]}{.metadata.namespace}{' '}{.metadata.name}{'\n'}{end}"||true)"
  fun_progress
  if [[ "${PX_NS_AND_ALL_PODS_DST}" != "" ]]; then
    PX_NS_DST="$(echo "${PX_NS_AND_ALL_PODS_DST}"|cut -d' ' -f1|head -1)"
    PX_ALL_PODS_DST="$(echo "${PX_NS_AND_ALL_PODS_DST}"|cut -d' ' -f2|xargs)"
    PX_1ST_POD_DST="$(echo "${PX_NS_AND_ALL_PODS_DST}"|cut -d' ' -f2|head -1|xargs)"
    printf "NS: ${PX_NS_DST}, Pods: ${PX_ALL_PODS_DST}\n" >> "${PX_LOG_FILE}"
  else
    printf "\n"
    printf "Error: Unable to identify portworx namespace and pods on the destination cluster, make sure portworx is set up and functioning.\n\n" | tee -a "${PX_LOG_FILE}";
    exit 1;
  fi
  printf "INFO|PX_NS_DST|${PX_NS_DST}\n" >> ${PX_RESOURCES_LOG_FILE}
  printf "INFO|PX_ALL_PODS_DST|${PX_ALL_PODS_DST}\n" >> ${PX_RESOURCES_LOG_FILE}

##Finding PX storage-cluster name.
  printf "Finding source PX storage-cluster name: " >> "${PX_LOG_FILE}"
  PX_STORAGE_CLUSTER_NAME_SRC="$(kubectl ${PX_KUBECONF_SRC} get storageclusters.core.libopenstorage.org -n ${PX_NS_SRC} -o jsonpath='{.items[0].metadata.name}'||true)"
  fun_progress
  if [[ "${PX_STORAGE_CLUSTER_NAME_SRC}" != "" ]]; then
    printf "${PX_STORAGE_CLUSTER_NAME_SRC}\n" >> "${PX_LOG_FILE}"
  else
    printf "\n"
    printf "Error: Unable to get source PX storage-cluster name, make sure portworx is set up and functioning.\n\n" | tee -a "${PX_LOG_FILE}";
    exit 1;
  fi
  printf "INFO|PX_STORAGE_CLUSTER_NAME_SRC|${PX_STORAGE_CLUSTER_NAME_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}

  printf "Finding destination PX storage-cluster name: " >> "${PX_LOG_FILE}"
  PX_STORAGE_CLUSTER_NAME_DST="$(kubectl ${PX_KUBECONF_DST} get storageclusters.core.libopenstorage.org -n ${PX_NS_DST} -o jsonpath='{.items[0].metadata.name}'||true)"
  fun_progress
  if [[ "${PX_STORAGE_CLUSTER_NAME_DST}" != "" ]]; then
    printf "${PX_STORAGE_CLUSTER_NAME_DST}\n" >> "${PX_LOG_FILE}"
  else
    printf "\n"
    printf "Error: Unable to get destination PX storage-cluster name, make sure portworx is set up and functioning.\n\n" | tee -a "${PX_LOG_FILE}";
    exit 1;
  fi
  printf "INFO|PX_STORAGE_CLUSTER_NAME_DST|${PX_STORAGE_CLUSTER_NAME_DST}\n" >> ${PX_RESOURCES_LOG_FILE}

##Set token for pxctl if Auth is enabled.
  printf "Checking: If authorization is enabled on the source cluster: " >> "${PX_LOG_FILE}"
  PX_AUTH_CHECK="$(kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} get storageclusters.core.libopenstorage.org ${PX_STORAGE_CLUSTER_NAME_SRC} -o custom-columns=":spec.security.enabled" --no-headers 2>/dev/null||true)"
  fun_progress
  if [[ "${PX_AUTH_CHECK}" == "true" ]]; then
    printf "Enabled, Going to add authorization token to all PX nodes.\n" >> "${PX_LOG_FILE}"
    printf "Getting PX authorization token from the source cluster: " >> "${PX_LOG_FILE}"
    ADMIN_TOKEN_SRC="$(kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} get secret px-admin-token -o jsonpath='{.data.auth-token}' | base64 -d 2> /dev/null)"
    fun_progress
    if [[ "${ADMIN_TOKEN_SRC}" != "" ]]; then
      printf "Successful\n" >> "${PX_LOG_FILE}"
      printf "Adding authorization token to the portworx nodes...\n" >> "${PX_LOG_FILE}"
      for PX_POD in ${PX_ALL_PODS_SRC}; do
        printf "Prcessing pod '"${PX_POD}"': " >> "${PX_LOG_FILE}"
        kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} exec -ti ${PX_POD} -c portworx -- /opt/pwx/bin/pxctl context create admin --token=$ADMIN_TOKEN_SRC >> "${PX_LOG_FILE}" 2>&1;
        fun_progress
      done
    else
      printf "\n"
      printf "Error; Authorization is enabled but unable to get authorization token.\n\n" | tee -a "${PX_LOG_FILE}";
      exit 1;
    fi
  else    
    printf "Disabled, Skipping add authorization token to PX nodes.\n" >> "${PX_LOG_FILE}"
  fi
  printf "Checking: If authorization is enabled on the destination cluster: " >> "${PX_LOG_FILE}"
  PX_AUTH_CHECK="$(kubectl ${PX_KUBECONF_DST} -n ${PX_NS_DST} get storageclusters.core.libopenstorage.org ${PX_STORAGE_CLUSTER_NAME_DST} -o custom-columns=":spec.security.enabled" --no-headers 2>/dev/null||true)"
  fun_progress
  if [[ "${PX_AUTH_CHECK}" == "true" ]]; then
    printf "Enabled, Going to add authorization token to all PX nodes.\n" >> "${PX_LOG_FILE}"
    printf "Getting PX authorization token from the destination cluster: " >> "${PX_LOG_FILE}"
    ADMIN_TOKEN_DST="$(kubectl ${PX_KUBECONF_DST} -n ${PX_NS_DST} get secret px-admin-token -o jsonpath='{.data.auth-token}' | base64 -d 2> /dev/null)"
    fun_progress
    if [[ "${ADMIN_TOKEN_DST}" != "" ]]; then
      printf "Successful\n" >> "${PX_LOG_FILE}"
      printf "Adding authorization token to the portworx nodes...\n" >> "${PX_LOG_FILE}"
      for PX_POD in ${PX_ALL_PODS_DST}; do
        printf "Prcessing pod '"${PX_POD}"': " >> "${PX_LOG_FILE}"
        kubectl ${PX_KUBECONF_DST} -n ${PX_NS_DST} exec -ti ${PX_POD} -c portworx -- /opt/pwx/bin/pxctl context create admin --token=$ADMIN_TOKEN_DST >> "${PX_LOG_FILE}" 2>&1;
        fun_progress
      done
    else
      printf "\n"
      printf "Error; Authorization is enabled but unable to get authorization token.\n\n" | tee -a "${PX_LOG_FILE}";
      exit 1;
    fi
  else    
    printf "Disabled, Skipping add authorization token to PX nodes.\n" >> "${PX_LOG_FILE}"
  fi

##Finding destination cluster UUID and cluster-pair token which will be used for cluster-pair generation..
  printf "Finding destination cluster UUID: " >> "${PX_LOG_FILE}"
  PX_DST_CLUSTER_UUID="$(kubectl ${PX_KUBECONF_DST} get storageclusters.core.libopenstorage.org ${PX_STORAGE_CLUSTER_NAME_DST} -n ${PX_NS_DST} -o jsonpath='{.status.clusterUid}{"\n"}' 2>> "${PX_LOG_FILE}")"
  fun_progress
  if [[ "${PX_DST_CLUSTER_UUID}" == "" ]]; then
    printf "\n"
    printf "Error: Unable to get destination portworx cluster UUID. See ${PX_LOG_FILE} for more information.\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1
  fi
  printf "${PX_DST_CLUSTER_UUID}\n" >> "${PX_LOG_FILE}"
  printf "INFO|PX_DST_CLUSTER_UUID|${PX_DST_CLUSTER_UUID}\n" >> ${PX_RESOURCES_LOG_FILE}

  printf "Finding destination cluster's cluster-pair token: " >> "${PX_LOG_FILE}"
  PX_CLUSTER_PAIR_TOKEN_DST="$(kubectl ${PX_KUBECONF_DST} exec -n ${PX_NS_DST} ${PX_1ST_POD_DST} -c portworx -- /opt/pwx/bin/pxctl cluster token show 2>> "${PX_LOG_FILE}"| grep -i 'Token is ' | cut -d' ' -f3)"
  fun_progress
  if [[ "${PX_CLUSTER_PAIR_TOKEN_DST}" == "" ]]; then
    printf "\n"
    printf "Error: Unable to get destination cluster-pair token. See ${PX_LOG_FILE} for more information.\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"
  PX_DR_MODE="DisasterRecovery"
  PX_CRDs_PREFIX=${PX_DST_CLUSTER_UUID}-${PX_NAMESPACE_TO_MIGRATE}
  PX_DIR_FOR_GENERATED_FILES="${PX_OUTPUT_DIR}/${PX_CRDs_PREFIX}";
  PX_API_LB_SVC_NAME="px-api-lb-service";
  mkdir -p ${PX_DIR_FOR_GENERATED_FILES}
  printf "Moving ${PX_RESOURCES_LOG_FILE} file to ${PX_DIR_FOR_GENERATED_FILES}/resources-created" >> "${PX_LOG_FILE}"
  mv ${PX_RESOURCES_LOG_FILE} ${PX_DIR_FOR_GENERATED_FILES}/resources-created
  PX_RESOURCES_LOG_FILE=${PX_DIR_FOR_GENERATED_FILES}/resources-created

##Create s3 object store credentials on both clusters.
  PX_OBJECT_STORE_CREDENTIALS_NAME="clusterPair_${PX_DST_CLUSTER_UUID}"
  if [[ "${PX_S3_DISABLE_SSL}" == "true" ]]; then
    PX_S3_DISABLE_SSL_OPTION="--s3-disable-ssl"
  else
    PX_S3_DISABLE_SSL_OPTION=""
  fi
  printf "Checking: If the object store credentials '${PX_OBJECT_STORE_CREDENTIALS_NAME}' already existing on the source cluster: " >> "${PX_LOG_FILE}"
  vRetVal="$(kubectl ${PX_KUBECONF_SRC} exec -n ${PX_NS_SRC} ${PX_1ST_POD_SRC} -c portworx -- /opt/pwx/bin/pxctl credentials validate ${PX_OBJECT_STORE_CREDENTIALS_NAME} 2>&1 | tr 'A-Z' 'a-z'||true)"
  fun_progress
  if [[ "${vRetVal}" == "credential validated successfully" ]]; then
    printf "Valid credentials found.\n" >> "${PX_LOG_FILE}"
  else
    if ( echo "${vRetVal}"| grep -i "validatecred: credential with name or uuid clusterpair_.* not found" >/dev/null); then
      printf "Not found, need to be created.\n" >> "${PX_LOG_FILE}"
    else
      printf "Invalid credentials found.\nGoing to delete the invalid credentials: " >> "${PX_LOG_FILE}"
      kubectl ${PX_KUBECONF_SRC} exec -n ${PX_NS_SRC} ${PX_1ST_POD_SRC} -c portworx -- /opt/pwx/bin/pxctl credentials delete ${PX_OBJECT_STORE_CREDENTIALS_NAME} 2>> "${PX_LOG_FILE}" >/dev/null
      fun_progress
      vRetVal="$(kubectl ${PX_KUBECONF_SRC} exec -n ${PX_NS_SRC} ${PX_1ST_POD_SRC} -c portworx -- /opt/pwx/bin/pxctl credentials validate ${PX_OBJECT_STORE_CREDENTIALS_NAME} 2>&1 | tr 'A-Z' 'a-z'||true)"
      fun_progress
      if ( echo "${vRetVal}"| grep -i "validatecred: credential with name or uuid clusterpair_.* not found" >/dev/null); then
        printf "Deleted\n" >> "${PX_LOG_FILE}"
      else
        printf "\n"
        printf "Unable to proceed. The invalid credentials could not be deleted.\n" | tee -a "${PX_LOG_FILE}"
        printf "Check ${PX_LOG_FILE} file for more information.\n\n"
        exit 1;
      fi
    fi
    printf "Creating new credentials: " >> "${PX_LOG_FILE}"
    kubectl ${PX_KUBECONF_SRC} exec -n ${PX_NS_SRC} ${PX_1ST_POD_SRC} -c portworx -- /opt/pwx/bin/pxctl credentials create \
        --provider s3 \
        --s3-access-key ${PX_S3_ACCESS_KEY_ID} \
        --s3-secret-key ${PX_S3_SECRET_KEY} \
        --s3-endpoint ${PX_S3_ENDPOINT} \
        --s3-region ${PX_AWS_REGION} ${PX_S3_DISABLE_SSL_OPTION} \
        --s3-storage-class STANDARD \
        ${PX_OBJECT_STORE_CREDENTIALS_NAME} >> "${PX_LOG_FILE}" 2>&1 && \
        printf "RESOURCE|SRC|NULL|object-store-credentials|${PX_OBJECT_STORE_CREDENTIALS_NAME}|${PX_KUBECONF_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}
    fun_progress
  fi
  printf "Checking: If the object store credentials '${PX_OBJECT_STORE_CREDENTIALS_NAME}' already existing on the destination cluster: " >> "${PX_LOG_FILE}"
  vRetVal="$(kubectl ${PX_KUBECONF_DST} exec -n ${PX_NS_DST} ${PX_1ST_POD_DST} -c portworx -- /opt/pwx/bin/pxctl credentials validate ${PX_OBJECT_STORE_CREDENTIALS_NAME} 2>&1 | tr 'A-Z' 'a-z'||true)"
  fun_progress
  if [[ "${vRetVal}" == "credential validated successfully" ]]; then
    printf "Valid credentials found.\n" >> "${PX_LOG_FILE}"
  else
    if ( echo "${vRetVal}"| grep -i "validatecred: credential with name or uuid clusterpair_.* not found" >/dev/null); then
      printf "Not found, need to be created.\n" >> "${PX_LOG_FILE}"
    else
      printf "Invalid credentials found.\nGoing to delete the invalid credentials: " >> "${PX_LOG_FILE}"
      kubectl ${PX_KUBECONF_DST} exec -n ${PX_NS_DST} ${PX_1ST_POD_DST} -c portworx -- /opt/pwx/bin/pxctl credentials delete ${PX_OBJECT_STORE_CREDENTIALS_NAME} 2>> "${PX_LOG_FILE}" >/dev/null
      fun_progress
      vRetVal="$(kubectl ${PX_KUBECONF_DST} exec -n ${PX_NS_DST} ${PX_1ST_POD_DST} -c portworx -- /opt/pwx/bin/pxctl credentials validate ${PX_OBJECT_STORE_CREDENTIALS_NAME} 2>&1 | tr 'A-Z' 'a-z'||true)"
      fun_progress
      if ( echo "${vRetVal}"| grep -i "validatecred: credential with name or uuid clusterpair_.* not found" >/dev/null); then
        printf "Deleted\n" >> "${PX_LOG_FILE}"
      else
        printf "\n"
        printf "Unable to proceed. The invalid credentials could not be deleted.\n" | tee -a "${PX_LOG_FILE}"
        printf "Check ${PX_LOG_FILE} file for more information.\n\n"
        exit 1;
      fi
    fi
    printf "Creating new credentials: " >> "${PX_LOG_FILE}"
    kubectl ${PX_KUBECONF_DST} exec -n ${PX_NS_DST} ${PX_1ST_POD_DST} -c portworx -- /opt/pwx/bin/pxctl credentials create \
        --provider s3 \
        --s3-access-key ${PX_S3_ACCESS_KEY_ID} \
        --s3-secret-key ${PX_S3_SECRET_KEY} \
        --s3-endpoint ${PX_S3_ENDPOINT} \
        --s3-region ${PX_AWS_REGION} ${PX_S3_DISABLE_SSL_OPTION} \
        --s3-storage-class STANDARD \
        ${PX_OBJECT_STORE_CREDENTIALS_NAME} >> "${PX_LOG_FILE}" 2>&1 && \
        printf "RESOURCE|DST|NULL|object-store-credentials|${PX_OBJECT_STORE_CREDENTIALS_NAME}|${PX_KUBECONF_DST}\n" >> ${PX_RESOURCES_LOG_FILE}
    fun_progress
  fi

##Checking: If the destination cluster's Portworx API is accessible on the source cluster through worker node's IP, If not expose it through a load-balancer service.
  printf "Finding the IP of a portworx node on destination cluster: " >> "${PX_LOG_FILE}"
  PX_SVC_HOST_DST="$(kubectl ${PX_KUBECONF_DST} get storagenodes.core.libopenstorage.org -n ${PX_NS_DST} -o jsonpath='{.items[1].status.network.mgmtIP}{"\n"}' 2>> "${PX_LOG_FILE}")"
  fun_progress
  if [[ "${PX_SVC_HOST_DST}" == "" ]]; then
    printf "\n"
    printf "Error: Unable to get worker nodes's IP to access the PX API.\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1
  fi
  printf " ${PX_SVC_HOST_DST}.\n" >> "${PX_LOG_FILE}"
  printf "Checking: If the destination cluster's Portworx API is accessible on the source cluster through '${PX_SVC_HOST_DST}' IP: " >> "${PX_LOG_FILE}"
  PX_VERSION_DST="$(kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} exec -ti -c portworx ${PX_1ST_POD_SRC} -- timeout 10 curl http://${PX_SVC_HOST_DST}:${PX_SVC_PORT_DST}/status 2>> /dev/null | grep '{"Version":".*","SchedulerInfo":{".*},"StorageSpec":'| cut -d',' -f1 | cut -d':' -f2 ||true)"
  fun_progress
  if [[ "${PX_VERSION_DST}" != "" ]]; then
    printf "API is accessible\n" >> "${PX_LOG_FILE}"
  else
    printf "API is not accessible. Need to access through a load-balancer service.\n" >> "${PX_LOG_FILE}"    
    printf "Checking: If the load-balancer service is already existing: " >> "${PX_LOG_FILE}"
    vRetVal="$(kubectl ${PX_KUBECONF_DST} get svc ${PX_API_LB_SVC_NAME} -n ${PX_NS_DST} -o jsonpath='{.metadata.name}' 2>> /dev/null || true)"
    fun_progress
    if [[ "${vRetVal}" == "${PX_API_LB_SVC_NAME}" ]]; then
      printf "It is existing. No need to create new one.\n" >> "${PX_LOG_FILE}"
    else
      printf "It is not existing.\n" >> "${PX_LOG_FILE}"
      printf "Going to creating a new load-balancer service: " >> "${PX_LOG_FILE}"
      PX_API_LB_SVC_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_API_LB_SVC_NAME}.yml";
      cat ./templates/px-api-lb-service.yaml | \
          sed "s,<PX_SVC_NAMESPACE>,${PX_NS_DST},g" | \
          sed "s,<PX_API_LB_SVC_NAME>,${PX_API_LB_SVC_NAME},g" > "${PX_API_LB_SVC_MANIFEST_FILE}"
      kubectl ${PX_KUBECONF_DST} apply -f ${PX_API_LB_SVC_MANIFEST_FILE} >/dev/null 2>>"${PX_LOG_FILE}" && \
          printf "RESOURCE|DST|${PX_NS_DST}|service|${PX_API_LB_SVC_NAME}|${PX_KUBECONF_DST}\n" >> ${PX_RESOURCES_LOG_FILE}
      fun_progress
      sleep 2
      printf "Service spec has been applied.\n" >> "${PX_LOG_FILE}"
    fi
    printf "Find the IP or the host name assigned to the API service...\n" >> "${PX_LOG_FILE}"
    vChecksDone=1;
    vTotalChecks=50;
    vSleepSeconds=10
    while (( vChecksDone <= vTotalChecks )); do
      printf "(Check ${vChecksDone}): " >> "${PX_LOG_FILE}"
      PX_SVC_HOST_DST="$(kubectl ${PX_KUBECONF_DST} get svc ${PX_API_LB_SVC_NAME} -n ${PX_NS_DST} -o jsonpath='{.status.loadBalancer.ingress[0].*}' 2>> /dev/null || true)"
      fun_progress
      if [[ "${PX_SVC_HOST_DST}" != "" ]]; then
        printf "Successful, Service host/ip: ${PX_SVC_HOST_DST}\n" >> "${PX_LOG_FILE}"
        break;
      else
        printf "Not found! Retrying...\n" >> "${PX_LOG_FILE}"
      fi
      vChecksDone=$(( vChecksDone + 1 ));
      sleep ${vSleepSeconds}
    done;
    if (( vChecksDone > vTotalChecks )); then
      printf "\n"
      printf "Unable to proceed. The IP or host name assigned to the Portworx API service at destination cluster not found. Check ${PX_LOG_FILE} file for more information.\n\n" | tee -a "${PX_LOG_FILE}"
      exit 1;
    fi
    printf "Checking: If the Portworx API service is reachable on the source cluster...\n" >> "${PX_LOG_FILE}"
    vChecksDone=1;
    vTotalChecks=50;
    vSleepSeconds=20
    while (( vChecksDone <= vTotalChecks )); do
      printf "(Check ${vChecksDone}): " >> "${PX_LOG_FILE}"
      PX_VERSION_DST="$(kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} exec -ti -c portworx ${PX_1ST_POD_SRC} -- timeout 10 curl http://${PX_SVC_HOST_DST}:${PX_SVC_PORT_DST}/status 2>> /dev/null | grep '{"Version":".*","SchedulerInfo":{".*},"StorageSpec":'| cut -d',' -f1 | cut -d':' -f2 || true)"
      fun_progress
      if [[ "${PX_VERSION_DST}" != "" ]]; then
        printf "API is reachable.\n" >> "${PX_LOG_FILE}"
        break;
      else
        printf "API is not ready, Retrying...\n" >> "${PX_LOG_FILE}"
      fi
      vChecksDone=$(( vChecksDone + 1 ));
      sleep ${vSleepSeconds}
    done;
    if (( vChecksDone > vTotalChecks )); then
      printf "\nUnable to proceed. The Portworx API service of destination cluster is not is reachable from the source cluster. Check ${PX_LOG_FILE} file for more information.\n\n" | tee -a "${PX_LOG_FILE}"
      exit 1;
    fi
  fi

##Generate and apply ClusterPair
  printf "Going to generate ClusterPair...\n" >> "${PX_LOG_FILE}"
  #Adding destination cluster details to the 'options' spec for cluster-pair.
  printf "Adding destination cluster details to the 'options' spec for cluster-pair: " >> "${PX_LOG_FILE}"
  PX_CLUSTER_PAIR_OPTIONS="$(cat ./templates/cluster-pair-options.yml | \
      sed "s,<PX_DST_PX_NODE_IP>,${PX_SVC_HOST_DST},g" | \
      sed "s,<PX_SVC_PORT_DST>,${PX_SVC_PORT_DST},g" | \
      sed "s,<PX_CLUSTER_PAIR_TOKEN_DST>,${PX_CLUSTER_PAIR_TOKEN_DST},g" | \
      sed "s,<PX_DR_MODE>,${PX_DR_MODE},g")"
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

  PX_CLUSTER_PAIR_NAME="${PX_CRDs_PREFIX}-cluster-pair";
  PX_AsyncDR_CRDs_NAMESPACE="kube-system";
  PX_CLUSTER_PAIR_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_CLUSTER_PAIR_NAME}.yml";
  printf "Generating ClusterPair manifest: ${PX_CLUSTER_PAIR_MANIFEST_FILE}\n" >> "${PX_LOG_FILE}"
  storkctl generate clusterpair ${PX_CLUSTER_PAIR_NAME} -n ${PX_AsyncDR_CRDs_NAMESPACE} ${PX_KUBECONF_DST} > "${PX_CLUSTER_PAIR_MANIFEST_FILE}" 2>> "${PX_LOG_FILE}"
  awk -v replc="${PX_CLUSTER_PAIR_OPTIONS//$'\n'/\\n}" '{gsub(/    insert_storage_options_here: .*/,replc)}1' "${PX_CLUSTER_PAIR_MANIFEST_FILE}"  > tmpfile && mv tmpfile "${PX_CLUSTER_PAIR_MANIFEST_FILE}"
  printf "Manifest for ClusterPair '${PX_CLUSTER_PAIR_NAME}' has been generated.\nApplying ClusterPair manifest: " >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_SRC} apply -f ${PX_CLUSTER_PAIR_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 && \
      printf "RESOURCE|SRC|${PX_AsyncDR_CRDs_NAMESPACE}|clusterpairs|${PX_CLUSTER_PAIR_NAME}|${PX_KUBECONF_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}
  sleep 5
  fun_progress

  vChecksDone=1;
  vTotalChecks=50;
  vSleepSeconds=10
  while (( vChecksDone <= vTotalChecks )); do
    printf "(Check ${vChecksDone}): Verify if ClusterPair is ready: " >> "${PX_LOG_FILE}"
    vRetVal="$(kubectl ${PX_KUBECONF_SRC} get clusterpairs.stork.libopenstorage.org ${PX_CLUSTER_PAIR_NAME} -n ${PX_AsyncDR_CRDs_NAMESPACE} -o jsonpath='{.status.schedulerStatus}{" "}{.status.storageStatus}' 2>> /dev/null || true)"
    if [[ "${vRetVal}" == "Ready Ready" ]]; then
      printf "Verified: ClusterPair is in ready state.\n" >> "${PX_LOG_FILE}"
      break;
    else
      printf "Not Ready, Retrying...\n" >> "${PX_LOG_FILE}"
    fi
    vChecksDone=$(( vChecksDone + 1 ));
    sleep ${vSleepSeconds} 
    fun_progress
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\nUnable to proceed. Issue: ClusterPair status is not ready. Trying to find the event logs for more information:\n\n" | tee -a "${PX_LOG_FILE}"
    vRetVal="$(kubectl ${PX_KUBECONF_SRC} get events -n ${PX_AsyncDR_CRDs_NAMESPACE} -o=jsonpath='{range .items[?(@.involvedObject.kind=="ClusterPair")]}{.message}{"\n"}{end}' 2>> "${PX_LOG_FILE}" || true )"
    if [[ "${vRetVal}" != "" ]]; then
      printf "${vRetVal}" | tee -a "${PX_LOG_FILE}"
    else
      printf "No event logs detected. Unable to identify the reason." | tee -a "${PX_LOG_FILE}"
    fi
    exit 1;
  fi
  printf "ClusterPair creation finished.\n" >> "${PX_LOG_FILE}"
  fun_progress

##Creating schedule policy.
  #PX_SCHEDULE_POLICY_INTERVAL_MINUTES= Defined in config-vars file
  #PX_SCHEDULE_POLICY_DAILY_TIME= Defined in config-vars file
  #PX_SCHEDULE_POLICY_NAME="-daily-$(date -d"${PX_SCHEDULE_POLICY_DAILY_TIME}" +%I-%M-%P)"
  PX_SCHEDULE_POLICY_NAME="${PX_CRDs_PREFIX}-schedule-policy"
  PX_SCHEDULE_POLICY_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_SCHEDULE_POLICY_NAME}.yml"
  printf "Creating schedule policy: " >> "${PX_LOG_FILE}"
  cat ./templates/schedule-policy.yml | \
      sed "s,<PX_SCHEDULE_POLICY_NAME>,${PX_SCHEDULE_POLICY_NAME},g" | \
      sed "s,<PX_SCHEDULE_POLICY_NAMESPACE>,${PX_AsyncDR_CRDs_NAMESPACE},g" | \
      sed "s,<PX_SCHEDULE_POLICY_INTERVAL_MINUTES>,${PX_SCHEDULE_POLICY_INTERVAL_MINUTES},g" | \
      sed "s,<PX_SCHEDULE_POLICY_DAILY_TIME>,${PX_SCHEDULE_POLICY_DAILY_TIME},g" > "${PX_SCHEDULE_POLICY_MANIFEST_FILE}"
  kubectl ${PX_KUBECONF_SRC} apply -f ${PX_SCHEDULE_POLICY_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 && \
      printf "RESOURCE|SRC|${PX_AsyncDR_CRDs_NAMESPACE}|schedulepolicies|${PX_SCHEDULE_POLICY_NAME}|${PX_KUBECONF_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}
  fun_progress

##Creating migration schedule.
  printf "Going to create the migration schedule: " >> "${PX_LOG_FILE}"
  PX_MIGRATION_SCHEDULE_NAME="${PX_CRDs_PREFIX}-migration-schedule"
  PX_MIGRATION_SCHEDULE_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_MIGRATION_SCHEDULE_NAME}.yml"
  fun_progress

  cat ./templates/migration-schedule.yml | \
      sed "s,<PX_MIGRATION_SCHEDULE_NAME>,${PX_MIGRATION_SCHEDULE_NAME},g" | \
      sed "s,<PX_MIGRATION_SCHEDULE_NAMESPACE>,${PX_AsyncDR_CRDs_NAMESPACE},g" | \
      sed "s,<PX_CLUSTER_PAIR_NAME>,${PX_CLUSTER_PAIR_NAME},g" | \
      sed "s,<PX_NAMESPACE_TO_MIGRATE>,${PX_NAMESPACE_TO_MIGRATE},g" | \
      sed "s,<PX_SCHEDULE_POLICY_NAME>,${PX_SCHEDULE_POLICY_NAME},g" > "${PX_MIGRATION_SCHEDULE_MANIFEST_FILE}"
  kubectl ${PX_KUBECONF_SRC} apply -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 && \
      printf "RESOURCE|SRC|${PX_AsyncDR_CRDs_NAMESPACE}|migrationschedules|${PX_MIGRATION_SCHEDULE_NAME}|${PX_KUBECONF_SRC}\n" >> ${PX_RESOURCES_LOG_FILE}
  printf "Migration schedule creation finished.\n" >> "${PX_LOG_FILE}"
  fun_progress

  vChecksDone=1
  vTotalChecks=500
  vSleepSeconds=20
  printf "Verify if application has been migrated to destination cluster.\n" >> "${PX_LOG_FILE}"
  while (( vChecksDone <= vTotalChecks )); do
    if [[ "${vChecksDone}" == "10" ]]; then
      printf "Taking really long, please wait till it finishes.\nFor debug open another terminal tab and try to describe the migration on source cluster as follows:\n" >> "${PX_LOG_FILE}"
      printf "kubectl ${PX_KUBECONF_SRC} describe -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} -n ${PX_AsyncDR_CRDs_NAMESPACE}\n" >> "${PX_LOG_FILE}"
    fi
    vRetVal="$(kubectl ${PX_KUBECONF_SRC} get -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} -n ${PX_AsyncDR_CRDs_NAMESPACE} -o jsonpath='{.status.items.Interval[0].status}' 2>> "${PX_LOG_FILE}" || true)"
    printf "(Check ${vChecksDone}): Current status is '${vRetVal}'\n" >> "${PX_LOG_FILE}"
    if [[ "${vRetVal}" == "Successful" ]]; then
      printf "Verified: The application has been migrated.\n" >> "${PX_LOG_FILE}"
      break;
    fi
    vChecksDone=$(( vChecksDone + 1 ));
    sleep ${vSleepSeconds}
    fun_progress
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\nUnable to migrate the application. Try to debug the issue.\nRefer the manifest files saved in: ${PX_DIR_FOR_GENERATED_FILES}\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1;
  fi
  fun_progress
  printf "\n";
  printf "Successfully set up AsyncDR replication.\n\n" | tee -a "${PX_LOG_FILE}"

##Calling clone creation script.
  printf "Preparing to start the application on remote cluster using PX Application-Clone." >> "${PX_LOG_FILE}"
  ./update.sh ${PX_NAMESPACE_TO_MIGRATE}
exit 0;
