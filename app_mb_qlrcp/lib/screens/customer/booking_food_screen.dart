import 'package:flutter/material.dart';
import '../../models/food.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/movie_service.dart';
import '../../utils/app_theme.dart';

class BookingFoodScreen extends StatefulWidget {
  final Movie movie;
  final Showtime showtime;
  final List<int> selectedSeatIds;

  const BookingFoodScreen({
    super.key,
    required this.movie,
    required this.showtime,
    required this.selectedSeatIds,
  });

  @override
  State<BookingFoodScreen> createState() => _BookingFoodScreenState();
}

class _BookingFoodScreenState extends State<BookingFoodScreen> {
  final _movieService = MovieService();

  List<Food> _foods = [];
  Map<int, int> _selectedFoods = {}; // foodId -> quantity
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);

    final result = await _movieService.getFoods();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _foods = result['foods'];
        }
      });
    }
  }

  void _updateQuantity(int foodId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedFoods.remove(foodId);
      } else {
        _selectedFoods[foodId] = quantity;
      }
    });
  }

  double _calculateFoodTotal() {
    double total = 0;
    _selectedFoods.forEach((foodId, quantity) {
      final food = _foods.firstWhere((f) => f.foodId == foodId);
      total += food.price * quantity;
    });
    return total;
  }

  void _handleContinue() {
    // Prepare food items for booking
    final foodItems = _selectedFoods.entries.map((entry) {
      final food = _foods.firstWhere((f) => f.foodId == entry.key);
      return {
        'food_id': entry.key,
        'quantity': entry.value,
        'price': food.price,
        'name': food.name,
      };
    }).toList();

    Navigator.of(context).pop({
      'selectedSeats': widget.selectedSeatIds,
      'foodItems': foodItems,
      'totalFood': _calculateFoodTotal(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Đồ Ăn & Thức Uống'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Movie & Showtime info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Text(
                        widget.movie.title,
                        style: AppTheme.headingMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.showtime.date} - ${widget.showtime.startTime}',
                        style: AppTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.selectedSeatIds.length} vé',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Foods list
                Expanded(
                  child: _foods.isEmpty
                      ? Center(
                          child: Text(
                            'Không có đồ ăn nào',
                            style: AppTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _foods.length,
                          itemBuilder: (context, index) {
                            final food = _foods[index];
                            final quantity = _selectedFoods[food.foodId] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Food info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            food.name,
                                            style: AppTheme.bodyMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (food.description != null)
                                            Text(
                                              food.description!,
                                              style: AppTheme.bodySmall,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${food.price.toStringAsFixed(0)}đ',
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.primaryOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity selector
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppTheme.primaryOrange,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _updateQuantity(
                                              food.foodId,
                                              quantity - 1,
                                            ),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.remove,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 40,
                                            alignment: Alignment.center,
                                            child: Text(
                                              quantity.toString(),
                                              style: AppTheme.bodyMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _updateQuantity(
                                              food.foodId,
                                              quantity + 1,
                                            ),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Total & Continue button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng đồ ăn:',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_calculateFoodTotal().toStringAsFixed(0)}đ',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _handleContinue,
                          child: Text(
                            _selectedFoods.isEmpty
                                ? 'Tiếp tục (không chọn đồ ăn)'
                                : 'Tiếp tục',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
