FROM kylincloud/shell-operator:v3.1

ENV  ANSIBLE_ROLES_PATH /kylincloud/installer/roles
WORKDIR /kylincloud
ADD controller/* /hooks/kylincloud/

ADD roles /kylincloud/installer/roles
ADD env /kylincloud/results/env
ADD playbooks /kylincloud/playbooks

#RUN chown kylincloud:kylincloud -R /kylincloud /hooks/kylincloud
USER kylincloud
