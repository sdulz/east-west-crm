typedef HaveNextType = bool Function(Map response, int pageNumber);
typedef ParamsType = Map<String, dynamic> Function(int pageIndex, int pageSize);

class PaginationResponseSetup {
  static HaveNextType _haveNext = (response, pageNumber) {
    if (response.containsKey("lastPage")) {
      return (response["lastPage"] ?? 0) > pageNumber;
    }
    if (response["data"] is Map && response["data"].containsKey("totalPages")) {
      return (response["data"]["totalPages"] ?? 0) > pageNumber;
    }
    return false;
  };
  static ParamsType _params = (pageNumber, pageSize) {
    return {"page": pageNumber, "pageSize": pageSize};
  };

  static int _pageSize = 10;

  static HaveNextType get haveNext => _haveNext;

  static ParamsType get params => _params;

  static int get pageSize => _pageSize;

  static void setup({
    required HaveNextType? haveNext,
    required ParamsType? paramsMap,
    required int? pageSize,
  }) {
    PaginationResponseSetup._haveNext = haveNext ?? _haveNext;
    PaginationResponseSetup._params = paramsMap ?? _params;
    PaginationResponseSetup._pageSize = pageSize ?? _pageSize;
  }
}
