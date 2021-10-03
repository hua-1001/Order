import 'dart:convert';
import 'package:html/parser.dart' show parse;

import 'package:task/models/my_webView_manager.dart';
import 'package:task/tools/error.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'request.dart';

String? _kParamsSceneId;

class Api {
  static Future<String> createOrder(PlatformAccountData task) async {
    try {
      var response = await _search(task);
      List list = response["list"];
      Map<String, dynamic> params = {
        'c_gender': response["c_gender"],
        'c_platform': task.platform.name,
        'c_vip_code': task.name,
        'i_job_id': list[0]["i_job_id"],
        'i_shop_id': list[0]["i_shop_id"],
        'path': ["job", "desktopVip"],
        'i_platform_id': task.name
      };
      var data = await Request.post("yutang/index.php/index/Order/addOrder",
          params: params);
      jsonDecode(data);
      return "预约成功;${list[0]["c_name"]}${list[0]["c_shop_name"]}";
    } on MError catch (e) {
      return Future.error(e);
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future queryTaskAvailable(PlatformAccountData task) async {
    try {
      await Request.post("yutang/index.php/toolsapi/ToolsApi/queryVipCode",
          params: {
            "c_vip_code": task.name,
            "api": "getVipCodeDown",
            "path": ["job", "desktopVip"]
          });
      return "查询成功";
    } catch (e) {
      return Future.error(e);
    }
  }

  // 搜索商品
  static Future _search(PlatformAccountData task) async {
    try {
      return await Request.post("yutang/index.php/index/Job/getJobByVipCode",
          params: {
            "page": 1,
            "limit": 10,
            "c_vip_code": task.name,
            "i_platform_id": task.platform.id,
            "windowNo": "137be1530135d041807cf5e03365b0cf",
            "sign": "3c922f937cb3388151463087333abd40",
          });
    } catch (e) {
      return Future.error(e);
    }
  }

  // 加载，获取必要参数
  static Future<bool> load() async {
    try {
      await UserInfo().setup();
      return true;
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<String?> qrCodeData() async {
    try {
      var response = await Request.get(
          "tbtools/index.php/index/Wechat/qrCodePath?indexUrl=/yutang/");
      _kParamsSceneId =
          parse(response).getElementById("sceneid")?.attributes["value"] ?? "";
      return "https://wxgzh.cklerp.com/yt/auth?sceneid=$_kParamsSceneId";
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future waitLogin() async {
    // 等待扫描
    try {
      var response = await Request.post("wx/qrcode.status",
          params: {"sceneid": _kParamsSceneId});
      if (response is Map) {
        var cookies = await MyWebViewManager().getCookie(wechatData: response);
        UserInfo().updateLoginInfo(cookies, wechatData: response, activeCode: "");
        return Future.value();
      }
    } catch (e) {
      return Future.error(e);
    }
  }
}