## 目录说明
|组件名称|组件简称|组件描述|
|-|-|-|
|create_gx|CGXS|图数据入库服务|
|data_integration|DACS|离线数据适配采集服务|
|data_model_service|DMS|数据模型服务（蓝鲸平台）：包含hive/mysql建库建表，调度任务导入|
|demo|DEMO|组件模板|
|logmgr|Logmgr|日志管理|
|meta_load|MRP|元数据入库程序|
|realtime_engine|RTE|指标实时计算引擎|
|reporter_system|RSP|可视化平台|
|sdk_ws|RIS|报表API接口|
|vbs_ws|DSI|大数据服务接口|
|streaming_load|LEP|日志数据入库程序|
|user_profile|UPS|用户画像生成服务|
|ws_outfile|DES|数据导出服务|

## 文件说明
|文件名称|文件说明|
|-|-|
|common_build_util.sh|打包脚本公共函数|
|common_dep_util.sh|部署升级脚本公共函数|
|default.ini|默认部署参数|
|params.ini|部署参数模板（请勿私自修改，修改时请在文件《部署升级参数修订记录.md》中添加修改记录）|
|部署升级参数修订记录.md|用于记录部署/升级模板参数修改修订记录，一般不允许私自修改，否则会造成部署或升级失败|
|script目录结构说明.md|当前目录结构说明文档|
