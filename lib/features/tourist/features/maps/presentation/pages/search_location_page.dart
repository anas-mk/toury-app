import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/location.dart';
import '../cubit/search_location_cubit.dart';
import '../cubit/search_location_state.dart';


class SearchLocationPage extends StatefulWidget {
  const SearchLocationPage({super.key});

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3D91)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Where to?',
          style: TextStyle(
            color: Color(0xFF0B3D91),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Content based on state
          Expanded(
            child: BlocBuilder<SearchLocationCubit, SearchLocationState>(
              builder: (context, state) {
                if (state is SearchLocationInitial) {
                  return _buildInitialView();
                } else if (state is SearchLocationLoading) {
                  return _buildLoadingView();
                } else if (state is SearchLocationLoaded) {
                  return _buildResultsView(state.locations);
                } else if (state is SearchLocationEmpty) {
                  return _buildEmptyView(state.query);
                } else if (state is SearchLocationError) {
                  return _buildErrorView(state.message);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            context.read<SearchLocationCubit>().search(value);
          },
          decoration: InputDecoration(
            hintText: 'Search for places (e.g., Cairo Tower)...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF0B3D91)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                context.read<SearchLocationCubit>().clear();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Initial View
  Widget _buildInitialView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSavedPlace(
          Icons.home,
          'Home',
          'Add your home address',
          null,
        ),
        _buildSavedPlace(
          Icons.work,
          'Work',
          'Add your work address',
          null,
        ),
        const SizedBox(height: 20),
        const Text(
          'Popular Places',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B3D91),
          ),
        ),
        const SizedBox(height: 10),
        _buildRecentSearch('Cairo Tower', 'Zamalek, Cairo'),
        _buildRecentSearch('Egyptian Museum', 'Tahrir Square, Cairo'),
        _buildRecentSearch('Pyramids of Giza', 'Giza'),
        _buildRecentSearch('Alexandria Library', 'Alexandria'),
        _buildRecentSearch('Khan el-Khalili', 'Cairo'),
      ],
    );
  }

  /// Loading View
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0B3D91),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching for "${_searchController.text}"...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Results View
  Widget _buildResultsView(List<Location> locations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Found ${locations.length} results',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: locations.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final location = locations[index];
              return _buildSearchResult(location);
            },
          ),
        ),
      ],
    );
  }

  /// Empty View
  Widget _buildEmptyView(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "$query"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Error View
  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  context
                      .read<SearchLocationCubit>()
                      .search(_searchController.text);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3D91),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSavedPlace(
      IconData icon,
      String title,
      String subtitle,
      Location? location,
      ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B3D91).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0B3D91)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      onTap: () {
        if (location != null) {
          Navigator.pop(context, location);
        }
      },
    );
  }

  Widget _buildRecentSearch(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.access_time, color: Colors.grey),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        _searchController.text = title;
        context.read<SearchLocationCubit>().search(title);
      },
    );
  }

  Widget _buildSearchResult(Location location) {
    final name = location.address ?? location.name ?? 'Unknown location';
    final displayName = name.split(',').first;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B3D91).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.place, color: Color(0xFF0B3D91)),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        name,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.pop(context, location);
      },
    );
  }
}