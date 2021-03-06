//
//  RESTRoutes.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire

enum RESTRoutes: URLRequestConvertible {
  //Router paths
  case authcode(clientId: String, scenario: AuthenticationMode)
  case token(code: String)
  case accounts
  case transactions(account: String, startDate: Date?, endDate: Date?, contKey: String?)

  //URL root and account api version are set in each bank specific loginworker implementation
  static var urlRoot: String = ""
  static var accountAPIVersion: String = ""

  var method: HTTPMethod {
    switch self {
    case .token:
      return .post
    default:
      return .get
    }
  }

  var route: (path: String, parameters: [String: Any]?) {
    switch self {
    case .authcode(let clientId, let scenario):
      return ("v2/authorize", ["state": "oauth2",
                               "client_id": clientId,
                               "scope": "ACCOUNTS_BASIC,ACCOUNTS_BALANCES,ACCOUNTS_DETAILS,ACCOUNTS_TRANSACTIONS",
                               "duration": 1234,
                               "accounts": "FI6593857450293470,FI4710113500010326,FI7473834510057469",
                               "language": "en",
                               "X-Response-Scenarios": scenario.rawValue,
                               "max_tx_history": 12,
                               "redirect_uri": clientRedirectURI])
    case .token(let code):
      return ("v2/authorize/access_token", ["code": code, "redirect_uri": clientRedirectURI])
    case .accounts:
      return (RESTRoutes.accountAPIVersion + "/accounts", nil)
    case .transactions(let accountId, let fromDate, let toDate, let continuationKey):
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"

      var endpoint = RESTRoutes.accountAPIVersion + "/accounts/\(accountId)/transactions"
      if let start = fromDate, let end = toDate {
        let fromString = dateFormatter.string(from: start)
        let endString = dateFormatter.string(from: end)
        endpoint = "\(endpoint)?fromDate=\(fromString)&toDate=\(endString)"
      }
      if let ckey = continuationKey {
        endpoint = "\(endpoint)&continuationKey=\(ckey)"
      }
      return (endpoint, nil)
    }
  }

  var encoding: Alamofire.ParameterEncoding {
    switch self.method {
    case .post, .put:
      return Alamofire.URLEncoding.default
    default:
      return Alamofire.URLEncoding.default
    }
  }

  //URLRequestConvertible protocol implementation
  func asURLRequest() throws -> URLRequest {
    guard let url = URL.init(string: self.route.path, relativeTo: URL.init(string: RESTRoutes.urlRoot)) else {
      throw NSError.init()
    }

    var request = URLRequest(url: url)
    request.httpMethod = self.method.rawValue

    let urlRequest = try self.encoding.encode(request, with: route.parameters)
    return urlRequest
  }
}
