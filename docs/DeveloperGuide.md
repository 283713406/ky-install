概述
------------
&ensp;&ensp;&ensp;&ensp;项目使用kubernetes job的形式实现kylincloud在已有k8s环境快速部署，采用[ansible](https://github.com/ansible/ansible)实现对kylincloud的统一配置及部署管理。

&ensp;&ensp;&ensp;&ensp;kylincloud各组件以角色(role)的形式划分，独立部署。
> ansible playbook及roles开发可参考：[Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html#working-with-playbooks)、[Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#roles)

项目结构
------------
```
|-- ks-installer
    |-- deploy                      
    |   |-- kylincloud.yaml                        # 部署用manifests
    |-- kylincloud.yaml                            # kylincloud playbook
    |-- roles                                      # 组件安装按角色划分
    |   |-- download              
    |   |-- ky-alerting           
    |   |-- ky-core
    |   |   |-- ingress             
    |   |   |-- ks-account
    |   |   |-- ks-apigateway
    |   |   |-- ks-apiserver
    |   |   |-- ks-console
    |   |   |-- ks-controller-manager
    |   |   |-- meta
    |   |   |-- prepare
    |   |-- ky-devops
    |   |   |-- gitlab
    |   |   |-- harbor
    |   |   |-- jenkins
    |   |   |-- ky-devops
    |   |   |-- meta
    |   |   |-- s2i
    |   |   |-- sonarqube
    |   |-- ky-istio
    |   |-- ky-logging
    |   |-- ky-monitor
    |   |-- ky-notification
    |   |-- kylincloud-defaults
    |   |-- metrics-server
    |   |-- openpitrix
    |-- scripts                                    # 功能脚本
        |-- download-docker-images.sh
    |-- Dockerfile
    |-- LICENSE
    |-- README.md
```

