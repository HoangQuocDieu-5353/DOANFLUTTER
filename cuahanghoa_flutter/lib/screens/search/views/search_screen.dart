import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuahanghoa_flutter/screens/search/views/components/search_form.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/screens/search/views/components/filter_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ProductService _productService = ProductService();
  final FocusNode _focusNode = FocusNode();

  List<ProductModel> _results = [];
  List<ProductModel> _originalResults = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String _sortOption = 'none';

  FilterOptions _currentFilters = FilterOptions();

  Stream<List<ProductModel>> _suggestionStream = Stream.value([]);
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_controller.text.isEmpty) {
        _suggestionStream = Stream.value([]);
        _results = [];
        _originalResults = [];
      } else {
        _suggestionStream = _productService.searchSuggestions(_controller.text);
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) _searchHistory.removeLast();
      await prefs.setStringList('search_history', _searchHistory);
      setState(() {});
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _results = [];
      _originalResults = [];
      _currentFilters = FilterOptions();
      _sortOption = 'none';
      _suggestionStream = Stream.value([]);
      _controller.text = query;
    });

    await _saveSearchHistory(query);
    final results = await _productService.searchProducts(query);

    setState(() {
      _results = results;
      _originalResults = results;
      _isLoading = false;
    });
  }

  // ⬇ MỞ BOTTOM SHEET LỌC
  Future<void> _openFilterSheet() async {
    _focusNode.unfocus();

    final newFilters = await showModalBottomSheet<FilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterBottomSheet(currentFilters: _currentFilters);
      },
    );

    if (newFilters != null) {
      setState(() {
        _currentFilters = newFilters;
      });
      await _applyFilters();
    }
  }

  // ⬇️ ÁP DỤNG LỌC (CÓ GỌI FIREBASE KHI CHỌN CATEGORY)
  Future<void> _applyFilters() async {
    // Nếu chọn danh mục → Lấy dữ liệu từ Firebase
    if (_currentFilters.category != null && _currentFilters.category!.isNotEmpty) {
      setState(() => _isLoading = true);

      //  FIXED: lấy snapshot đầu tiên từ Stream
      final categoryResults = await _productService
          .getProductsByCategory(_currentFilters.category!)
          .first;

      List<ProductModel> filteredList = List.from(categoryResults);

      // Lọc theo giá
      if (_currentFilters.minPrice != null) {
        filteredList =
            filteredList.where((p) => p.price >= _currentFilters.minPrice!).toList();
      }
      if (_currentFilters.maxPrice != null) {
        filteredList =
            filteredList.where((p) => p.price <= _currentFilters.maxPrice!).toList();
      }

      setState(() {
        _results = filteredList;
        _originalResults = filteredList;
        _isLoading = false;
      });
    } else {
      // Nếu không chọn danh mục → lọc theo giá trong danh sách hiện tại
      List<ProductModel> filteredList = List.from(_originalResults);

      if (_currentFilters.minPrice != null) {
        filteredList =
            filteredList.where((p) => p.price >= _currentFilters.minPrice!).toList();
      }
      if (_currentFilters.maxPrice != null) {
        filteredList =
            filteredList.where((p) => p.price <= _currentFilters.maxPrice!).toList();
      }

      setState(() {
        _results = filteredList;
        _sortResults(_sortOption, applyToOriginal: false);
      });
    }
  }

  //  SẮP XẾP
  void _sortResults(String option, {bool applyToOriginal = true}) {
    setState(() {
      _sortOption = option;
      _results = _productService.sortProducts(_results, option);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tìm kiếm"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchForm(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: false,
              onFieldSubmitted: (value) {
                if (value != null && value.isNotEmpty) {
                  _searchProducts(value);
                }
              },
              onTabFilter: _openFilterSheet,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_results.isNotEmpty || _originalResults.isNotEmpty) {
      return _buildResultsList();
    }
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      return _buildSuggestionsList();
    }
    return _buildSearchHistory();
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(child: Text("Nhập để tìm kiếm hoa..."));
    }
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Tìm kiếm gần đây",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('search_history');
                setState(() => _searchHistory = []);
              },
              child: const Text("Xóa tất cả", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
        ..._searchHistory.map((term) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(term),
              onTap: () => _searchProducts(term),
            )),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return StreamBuilder<List<ProductModel>>(
      stream: _suggestionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("Không tìm thấy gợi ý cho '${_controller.text}'"));
        }

        final suggestions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final p = suggestions[index];
            return ListTile(
              leading: Image.network(
                p.imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              ),
              title: Text(p.name),
              subtitle:
                  Text(currencyFormatter.format(p.price), style: const TextStyle(color: Colors.red)),
              onTap: () => _searchProducts(p.name),
            );
          },
        );
      },
    );
  }

  Widget _buildResultsList() {
    if (_results.isEmpty && _originalResults.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Không tìm thấy sản phẩm nào khớp với bộ lọc của bạn.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<String>(
              value: _sortOption,
              items: const [
                DropdownMenuItem(value: 'none', child: Text("Sắp xếp")),
                DropdownMenuItem(value: 'price_low_to_high', child: Text("Giá: Thấp đến Cao")),
                DropdownMenuItem(value: 'price_high_to_low', child: Text("Giá: Cao đến Thấp")),
                DropdownMenuItem(value: 'name_a_z', child: Text("Tên: A → Z")),
                DropdownMenuItem(value: 'name_z_a', child: Text("Tên: Z → A")),
              ],
              onChanged: (val) {
                if (val != null) _sortResults(val);
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final p = _results[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Image.network(
                    p.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  ),
                  title: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(currencyFormatter.format(p.price),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      productDetailsScreenRoute,
                      arguments: p.id,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
