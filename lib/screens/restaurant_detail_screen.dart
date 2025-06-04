import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant_detail.dart';
import '../services/restaurant_detail_service.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String placeId;
  final String? initialName; // 可选的初始名称，用于显示loading时的标题

  const RestaurantDetailScreen({
    super.key, 
    required this.placeId,
    this.initialName,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final RestaurantDetailService _service = RestaurantDetailService();
  RestaurantDetail? _restaurant;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetail();
  }

  Future<void> _loadRestaurantDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final restaurant = await _service.getRestaurantDetail(widget.placeId);
      
      setState(() {
        _restaurant = restaurant;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildDetailContent(),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: const Color(0xFFE95322),
          title: Text(
            widget.initialName ?? 'Loading...',
            style: const TextStyle(color: Colors.white),
          ),
          flexibleSpace: const FlexibleSpaceBar(
            background: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFE95322)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFFE95322),
          title: const Text('Error', style: TextStyle(color: Colors.white)),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load restaurant details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRestaurantDetail,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailContent() {
    if (_restaurant == null) return const SizedBox.shrink();

    final photoUrls = _service.getPhotoUrls(_restaurant!, limit: 10);
    
    return CustomScrollView(
      slivers: [
        // 照片画廊头部
        _buildPhotoHeader(photoUrls),
        
        // 详细信息内容
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(),
                const SizedBox(height: 24),
                _buildContactInfo(),
                const SizedBox(height: 24),
                _buildOpeningHours(),
                const SizedBox(height: 24),
                _buildReviews(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoHeader(List<String> photoUrls) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFFE95322),
      title: Text(
        _restaurant!.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: photoUrls.isNotEmpty
            ? PageView.builder(
                itemCount: photoUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        photoUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 64),
                            ),
                      ),
                      // 渐变遮罩，使标题更易读
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black26,
                            ],
                          ),
                        ),
                      ),
                      // 照片指示器
                      if (photoUrls.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              photoUrls.length,
                              (dotIndex) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotIndex == index 
                                      ? Colors.white 
                                      : Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            : Container(
                color: const Color(0xFFE95322),
                child: const Center(
                  child: Icon(Icons.restaurant, size: 80, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 餐厅名称和状态
        Row(
          children: [
            Expanded(
              child: Text(
                _restaurant!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF391713),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _restaurant!.currentlyOpen == true 
                    ? Colors.green 
                    : Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _service.getOpenStatusText(_restaurant!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 评分和价格
        Row(
          children: [
            if (_restaurant!.rating != null) ...[
              Icon(Icons.star, color: Colors.amber[700], size: 20),
              const SizedBox(width: 4),
              Text(
                _restaurant!.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF391713),
                ),
              ),
              const SizedBox(width: 4),
              if (_restaurant!.userRatingsTotal != null)
                Text(
                  '(${_restaurant!.userRatingsTotal} reviews)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(width: 16),
            ],
            
            if (_restaurant!.priceLevel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE95322)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _restaurant!.priceRange,
                  style: const TextStyle(
                    color: Color(0xFFE95322),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 菜系类型
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _service.getFormattedCuisineTypes(_restaurant!).map((cuisine) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE95322).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cuisine,
                style: const TextStyle(
                  color: Color(0xFFE95322),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ).toList(),
        ),
        
        // 简介
        if (_restaurant!.editorialSummary != null) ...[
          const SizedBox(height: 16),
          Text(
            _restaurant!.editorialSummary!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF391713),
          ),
        ),
        const SizedBox(height: 12),
        
        // 地址
        _buildInfoRow(
          Icons.location_on,
          'Address',
          _restaurant!.formattedAddress,
          onTap: () => _launchMaps(),
        ),
        
        // 电话
        if (_restaurant!.formattedPhoneNumber != null)
          _buildInfoRow(
            Icons.phone,
            'Phone',
            _restaurant!.formattedPhoneNumber!,
            onTap: () => _launchPhone(_restaurant!.formattedPhoneNumber!),
          ),
        
        // 网站
        if (_restaurant!.website != null)
          _buildInfoRow(
            Icons.language,
            'Website',
            _restaurant!.website!,
            onTap: () => _launchWebsite(_restaurant!.website!),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFFE95322)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null ? const Color(0xFF386BF6) : const Color(0xFF391713),
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHours() {
    final hours = _service.getFormattedOpeningHours(_restaurant!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opening Hours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF391713),
          ),
        ),
        const SizedBox(height: 12),
        ...hours.map((hour) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            hour,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF391713),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildReviews() {
    if (_restaurant!.reviews.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF391713),
          ),
        ),
        const SizedBox(height: 12),
        ...(_restaurant!.reviews.take(3).map((review) => _buildReviewCard(review))),
        if (_restaurant!.reviews.length > 3)
          TextButton(
            onPressed: () {
              // TODO: 显示所有评论的页面
            },
            child: const Text('View all reviews'),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: review.profilePhotoUrl != null
                      ? NetworkImage(review.profilePhotoUrl!)
                      : null,
                  child: review.profilePhotoUrl == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < review.rating ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber[700],
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review.relativeTimeDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _service.getFormattedReviewText(review),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _launchMaps,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE95322),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.directions),
            label: const Text('Directions'),
          ),
        ),
        const SizedBox(width: 12),
        if (_restaurant!.formattedPhoneNumber != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchPhone(_restaurant!.formattedPhoneNumber!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE95322),
                side: const BorderSide(color: Color(0xFFE95322)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
            ),
          ),
      ],
    );
  }

  Future<void> _launchMaps() async {
    final lat = _restaurant!.geometry.location.lat;
    final lng = _restaurant!.geometry.location.lng;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchWebsite(String website) async {
    if (await canLaunchUrl(Uri.parse(website))) {
      await launchUrl(Uri.parse(website));
    }
  }
} 