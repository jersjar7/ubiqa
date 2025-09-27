// lib/ui/2_presentation/features/listings/widgets/listing_detail_panel.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Import contracts
import '../../../../../services/1_contracts/features/listings/listings_repository.dart';

// Import utils
import '../../../../../utils/price_formatter.dart';

/// Listing Detail Panel Widget
///
/// Fixed bottom panel (45% height) showing listing details.
/// User can tap different bubbles to update content.
class ListingDetailPanel extends StatelessWidget {
  final ListingWithDetails listingDetail;
  final VoidCallback onClose;

  const ListingDetailPanel({
    super.key,
    required this.listingDetail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          onClose();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotosCarousel(),
                    const SizedBox(height: 16),
                    _buildPrice(),
                    const SizedBox(height: 16),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSpecs(),
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const SizedBox(height: 16),
                    _buildLocation(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildContactButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }

  Widget _buildPhotosCarousel() {
    final photos = listingDetail.property.media.propertyPhotoUrls;

    if (photos.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(photos[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrice() {
    return Text(
      PriceFormatter.formatFullPrice(listingDetail.listing.price),
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      listingDetail.listing.title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSpecs() {
    final specs = listingDetail.property.specs;

    return Row(
      children: [
        if (specs.bedroomCount != null) ...[
          _buildSpecItem(Icons.bed, '${specs.bedroomCount} hab'),
          const SizedBox(width: 16),
        ],
        if (specs.bathroomCount != null) ...[
          _buildSpecItem(Icons.bathtub, '${specs.bathroomCount} baño'),
          const SizedBox(width: 16),
        ],
        _buildSpecItem(
          Icons.straighten,
          '${specs.totalAreaInSquareMeters.toInt()} m²',
        ),
        if (specs.availableParkingSpaces > 0) ...[
          const SizedBox(width: 16),
          _buildSpecItem(Icons.garage, '${specs.availableParkingSpaces} est'),
        ],
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          listingDetail.listing.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                listingDetail.property.location
                    .generateFormattedAddressForDisplay(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _launchWhatsApp(context),
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              'Contactar por WhatsApp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final contactInfo = listingDetail.listing.contactInfo;

    if (contactInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Información de contacto no disponible')),
      );
      return;
    }

    final phone = contactInfo.getInternationalPhoneNumber();
    final message =
        'Hola, estoy interesado en tu propiedad: ${listingDetail.listing.title}';
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }
}
