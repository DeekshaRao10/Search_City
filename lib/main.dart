import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CitySearchApp());
}

// ============================================================
// APP
// ============================================================

class CitySearchApp extends StatelessWidget {
  const CitySearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'City Search',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const CitySearchScreen(),
    );
  }
}

// ============================================================
// CITY MODEL
// ============================================================

class City {
  final String name;
  final String location;
  final String? image;

  const City({
    required this.name,
    required this.location,
    this.image,
  });
}

// ============================================================
// CITY API SERVICE
// ============================================================

class CityService {
  Future<List<String>> searchCities(String query) async {
    final url = Uri.parse(
      'https://api.milescaira.com/account/city-autocomplete/?query=${Uri.encodeComponent(query)}',
    );

    debugPrint('API URL: $url');

    final response = await http.get(url);

    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'API failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    return List<String>.from(
      data['suggestions'] ?? [],
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() =>
      _CitySearchScreenState();
}

class _CitySearchScreenState
    extends State<CitySearchScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _searchController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final CityService _cityService = CityService();

  // ==========================================================
  // SEARCH VARIABLES
  // ==========================================================

  Timer? _debounce;

  List<String> _suggestions = [];

  bool _isLoading = false;
  bool _hasError = false;
  bool _hasSearched = false;

  String? _selectedCity;

  bool _isSelectingCity = false;

  // Fixed current location
  final String _currentLocation = 'Bengaluru, India';

  int _currentPage = 0;

  // Used to ignore old API responses
  int _searchRequestId = 0;

  // ==========================================================
  // POPULAR CITIES
  // ==========================================================

  final List<City> _popularCities = const [
    City(
      name: 'Bengaluru',
      location: 'Karnataka, India',
      image: 'assets/cities/bangalore.jpg',
    ),
    City(
      name: 'Bandung',
      location: 'West Java, Indonesia',
      image: 'assets/cities/bandung.jpg',
    ),
    City(
      name: 'Bangkok',
      location: 'Thailand',
      image: 'assets/cities/bangkok.jpg',
    ),
    City(
      name: 'Banff',
      location: 'Alberta, Canada',
      image: 'assets/cities/banff.jpg',
    ),
    City(
      name: 'London',
      location: 'United Kingdom',
      image: 'assets/cities/london.jpg',
    ),
    City(
      name: 'Paris',
      location: 'France',
      image: 'assets/cities/paris.jpg',
    ),
    City(
      name: 'Singapore',
      location: 'Singapore',
      image: 'assets/cities/singapore.jpg',
    ),
    City(
      name: 'Sydney',
      location: 'Australia',
      image: 'assets/cities/sydney.jpg',
    ),
    City(
      name: 'Tokyo',
      location: 'Japan',
      image: 'assets/cities/tokyo.jpg',
    ),
    City(
      name: 'Dubai',
      location: 'United Arab Emirates',
      image: 'assets/cities/dubai.jpg',
    ),
  ];

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _scrollController.addListener(
      _onScroll,
    );
  }

  // ==========================================================
  // SEARCH TEXT CHANGED
  // ==========================================================

  void _onSearchChanged() {
    if (_isSelectingCity) {
      return;
    }

    final query =
        _searchController.text.trim();

    // Immediately rebuild clear button/dropdown
    if (mounted) {
      setState(() {});
    }

    _debounce?.cancel();

    // --------------------------------------------------------
    // EMPTY SEARCH
    // --------------------------------------------------------

    if (query.isEmpty) {
      _searchRequestId++;

      setState(() {
        _suggestions = [];
        _isLoading = false;
        _hasError = false;
        _hasSearched = false;
        _selectedCity = null;
        _currentPage = 0;
      });

      return;
    }

    // --------------------------------------------------------
    // DEBOUNCE
    // --------------------------------------------------------

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        _searchCities(query);
      },
    );
  }

  // ==========================================================
  // SEARCH API
  // ==========================================================

  Future<void> _searchCities(
    String query,
  ) async {
    final requestId =
        ++_searchRequestId;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasSearched = false;
    });

    try {
      final results =
          await _cityService.searchCities(
        query,
      );

      // Ignore old response
      if (requestId != _searchRequestId) {
        return;
      }

      if (!mounted) return;

      // Make sure the text hasn't changed
      if (_searchController.text.trim() !=
          query) {
        return;
      }

      setState(() {
        _suggestions = results;
        _isLoading = false;
        _hasError = false;
        _hasSearched = true;
      });
    } catch (e) {
      debugPrint(
        'SEARCH ERROR: $e',
      );

      if (requestId != _searchRequestId) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _suggestions = [];
        _isLoading = false;
        _hasError = true;
        _hasSearched = true;
      });
    }
  }

  // ==========================================================
  // SELECT CITY
  // ==========================================================

  void _selectCity(
    String cityName,
  ) {
    _debounce?.cancel();

    // Invalidate previous request
    _searchRequestId++;

    _isSelectingCity = true;

    setState(() {
      _selectedCity = cityName;

      _suggestions = [];

      _isLoading = false;

      _hasError = false;

      _hasSearched = false;

      _currentPage = 0;
    });

    _searchController.value =
        TextEditingValue(
      text: cityName,
      selection:
          TextSelection.collapsed(
        offset: cityName.length,
      ),
    );

    // Move cards to first position
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        _isSelectingCity = false;
      },
    );
  }

  // ==========================================================
  // CLEAR SEARCH
  // ==========================================================

  void _clearSearch() {
    _debounce?.cancel();

    _searchRequestId++;

    _isSelectingCity = true;

    _searchController.clear();

    setState(() {
      _selectedCity = null;

      _suggestions = [];

      _isLoading = false;

      _hasError = false;

      _hasSearched = false;

      _currentPage = 0;
    });

    _isSelectingCity = false;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration:
            const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    }
  }

  // ==========================================================
  // CARD SCROLL
  // ==========================================================

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    // 250 card width + 16 spacing
    const double cardStep = 266;

    final page =
        (_scrollController.offset /
                cardStep)
            .round();

    final maxPage =
        _displayCities.isEmpty
            ? 0
            : _displayCities.length - 1;

    final safePage =
        page.clamp(
      0,
      maxPage,
    );

    if (safePage != _currentPage) {
      setState(() {
        _currentPage = safePage;
      });
    }
  }

  // ==========================================================
  // FIND POPULAR CITY
  // ==========================================================

  City? _findPopularCity(
    String cityName,
  ) {
    final normalized =
        cityName.trim().toLowerCase();

    // Exact match
    for (final city in _popularCities) {
      if (city.name.toLowerCase() ==
          normalized) {
        return city;
      }
    }

    // Handle Bangalore typo
    if (normalized == 'banglore') {
      return _popularCities.first;
    }

    return null;
  }

  // ==========================================================
  // DISPLAY CITIES
  // ==========================================================

  List<City> get _displayCities {
    // No selection
    if (_selectedCity == null ||
        _selectedCity!.trim().isEmpty) {
      return _popularCities;
    }

    // Popular city
    final popularCity =
        _findPopularCity(
      _selectedCity!,
    );

    if (popularCity != null) {
      return [popularCity];
    }

    // Non-popular searched city
    return [
      City(
        name: _selectedCity!,
        location: 'Selected city',
        image: null,
      ),
    ];
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayCities =
        _displayCities;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF071A3A),
              Color(0xFF092A57),
              Color(0xFF06152F),
            ],
          ),
        ),

        child: SafeArea(
          child: Stack(
            children: [
              // ==================================================
              // BACKGROUND GLOW
              // ==================================================

              Positioned(
                top: -100,
                right: -100,

                child: Container(
                  width: 300,
                  height: 300,

                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,

                    color:
                        const Color(
                      0xFF168AFF,
                    ).withOpacity(
                      0.12,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: -120,
                left: -100,

                child: Container(
                  width: 300,
                  height: 300,

                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,

                    color:
                        const Color(
                      0xFF0A7CFF,
                    ).withOpacity(
                      0.10,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // MAIN CONTENT
              // ==================================================

              SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center,

                    children: [
                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'Search Your City',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          fontSize: 34,

                          fontWeight:
                              FontWeight.w800,

                          letterSpacing:
                              -0.8,

                          color:
                              Color(0xFF2D9CFF),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Discover amazing places around the world',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          fontSize: 15,

                          color: Colors
                              .white
                              .withOpacity(
                            0.68,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // SEARCH FIELD
                      // ==================================================

                      _buildSearchField(),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // LOCATION
                      // ==================================================

                      _buildLocationBadge(),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // POPULAR CITIES + CARDS
                      // ==================================================

                      _buildPopularCitiesSection(
                        displayCities,
                      ),

                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // POPULAR CITIES SECTION
  // ============================================================

  Widget _buildPopularCitiesSection(
    List<City> displayCities,
  ) {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        // ========================================================
        // NORMAL CONTENT
        // ========================================================

        Column(
          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              crossAxisAlignment:
                  CrossAxisAlignment.center,

              children: [
                Text(
                  'Popular Cities',

                  style:
                      TextStyle(
                    fontSize: 20,

                    fontWeight:
                        FontWeight.w700,

                    color: Colors.white
                        .withOpacity(
                      0.95,
                    ),
                  ),
                ),

                Text(
                  '${displayCities.length == _popularCities.length ? 10 : displayCities.length} cities',

                  style:
                      TextStyle(
                    fontSize: 12,

                    color: Colors.white
                        .withOpacity(
                      0.55,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // CARDS
            // ----------------------------------------------------

            SizedBox(
              height: 285,

              child: ListView.builder(
                controller:
                    _scrollController,

                scrollDirection:
                    Axis.horizontal,

                physics:
                    const BouncingScrollPhysics(),

                itemCount:
                    displayCities.length,

                itemBuilder:
                    (context, index) {
                  final city =
                      displayCities[index];

                  final isSelected =
                      _selectedCity !=
                          null &&
                      city.name
                              .toLowerCase() ==
                          _selectedCity!
                              .toLowerCase();

                  return Padding(
                    padding:
                        EdgeInsets.only(
                      right:
                          index ==
                                  displayCities
                                      .length -
                                      1
                              ? 0
                              : 16,
                    ),

                    child:
                        _buildCityCard(
                      city,
                      index,
                      isSelected,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ----------------------------------------------------
            // PAGINATION
            // ----------------------------------------------------

            if (displayCities.length > 1)
              _buildPagination(
                displayCities.length,
              ),
          ],
        ),

        // ========================================================
        // FLOATING AUTOCOMPLETE
        //
        // It is intentionally positioned over the
        // LEFT side of the city images.
        // ========================================================

        if (_searchController.text
                .trim()
                .isNotEmpty)
          Positioned(
            left: 12,

            // Header is approximately 32px.
            // 50px puts dropdown over the
            // upper part of the images.
            top: 55,

            child:
                _buildSearchDropdown(
              context,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _buildSearchField() {
    final hasText =
        _searchController
            .text
            .isNotEmpty;

    return Container(
      height: 60,

      decoration:
          BoxDecoration(
        color: Colors.white
            .withOpacity(0.09),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: Colors.white
              .withOpacity(0.13),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.20),

            blurRadius: 25,

            offset:
                const Offset(0, 10),
          ),
        ],
      ),

      child: TextField(
        controller:
            _searchController,

        style:
            const TextStyle(
          color:
              Colors.white,

          fontSize: 16,
        ),

        cursorColor:
            const Color(
          0xFF2D9CFF,
        ),

        decoration:
            InputDecoration(
          hintText:
              'Search for a city...',

          hintStyle:
              TextStyle(
            color: Colors.white
                .withOpacity(
              0.45,
            ),

            fontSize: 15,
          ),

          prefixIcon:
              const Icon(
            Icons.search_rounded,

            color:
                Color(0xFF2D9CFF),

            size: 24,
          ),

          // CLEAR BUTTON
          suffixIcon:
              hasText
                  ? IconButton(
                      tooltip:
                          'Clear',

                      onPressed:
                          _clearSearch,

                      icon:
                          Icon(
                        Icons
                            .close_rounded,

                        color: Colors
                            .white
                            .withOpacity(
                          0.65,
                        ),

                        size: 25,
                      ),
                    )
                  : null,

          border:
              InputBorder.none,

          contentPadding:
              const EdgeInsets
                  .symmetric(
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION BADGE
  // ============================================================

  Widget _buildLocationBadge() {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 14,
        vertical: 9,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF0B315E,
        ).withOpacity(
          0.85,
        ),

        borderRadius:
            BorderRadius.circular(
          30,
        ),

        border: Border.all(
          color:
              const Color(
            0xFF2D9CFF,
          ).withOpacity(
            0.25,
          ),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons.location_on_rounded,

            size: 16,

            color:
                Color(0xFF2D9CFF),
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            '$_currentLocation • Your location',

            style:
                TextStyle(
              fontSize: 12.5,

              color: Colors.white
                  .withOpacity(
                0.82,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH DROPDOWN
  // ============================================================

  Widget _buildSearchDropdown(
    BuildContext context,
  ) {
    final query =
        _searchController
            .text
            .trim();

    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // RESPONSIVE WIDTH
    // ==========================================================

    final screenWidth =
        MediaQuery.of(context)
            .size
            .width;

    final dropdownWidth =
        screenWidth > 900
            ? 430.0
            : screenWidth - 70;

    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return _buildDropdownContainer(
        width: dropdownWidth,

        child: SizedBox(
          height: 58,

          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
            ),

            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,

                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,

                    color:
                        Color(0xFF2D9CFF),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Text(
                  'Searching cities...',

                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.70,
                    ),

                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_hasError) {
      return _buildDropdownContainer(
        width: dropdownWidth,

        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          child: Row(
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,

                color:
                    Colors.redAccent,

                size: 20,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  'Unable to search cities. '
                  'Please try again.',

                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.80,
                    ),

                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // EMPTY RESULT
    // ==========================================================

    if (_hasSearched &&
        _suggestions.isEmpty) {
      return _buildDropdownContainer(
        width: dropdownWidth,

        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          child: Row(
            children: [
              Icon(
                Icons
                    .location_off_outlined,

                color: Colors.white
                    .withOpacity(
                  0.55,
                ),

                size: 20,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  'No matching Cities found.',

                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.72,
                    ),

                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // NO RESULTS YET
    // ==========================================================

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // RESULTS
    // ==========================================================

    return _buildDropdownContainer(
      width: dropdownWidth,

      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxHeight: 225,
        ),

        child:
            ListView.separated(
          shrinkWrap: true,

          padding:
              EdgeInsets.zero,

          itemCount:
              _suggestions.length,

          separatorBuilder:
              (context, index) {
            return Divider(
              height: 1,

              thickness: 1,

              color: Colors.white
                  .withOpacity(
                0.07,
              ),
            );
          },

          itemBuilder:
              (context, index) {
            final city =
                _suggestions[index];

            return Material(
              color:
                  Colors.transparent,

              child: InkWell(
                onTap: () {
                  _selectCity(
                    city,
                  );
                },

                child: SizedBox(
                  height: 50,

                  child: Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                    ),

                    child: Row(
                      children: [
                        // ------------------------------------------
                        // ICON
                        // ------------------------------------------

                        Container(
                          width: 34,
                          height: 34,

                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape
                                    .circle,

                            color:
                                const Color(
                              0xFF2D9CFF,
                            ).withOpacity(
                              0.12,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons
                                .location_city_rounded,

                            color:
                                Color(
                              0xFF2D9CFF,
                            ),

                            size: 18,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        // ------------------------------------------
                        // CITY NAME
                        // ------------------------------------------

                        Expanded(
                          child:
                              Text(
                            city,

                            maxLines:
                                1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  14,

                              fontWeight:
                                  FontWeight
                                      .w500,
                            ),
                          ),
                        ),

                        // ------------------------------------------
                        // ARROW
                        // ------------------------------------------

                        Icon(
                          Icons
                              .chevron_right_rounded,

                          color: Colors
                              .white
                              .withOpacity(
                            0.38,
                          ),

                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN CONTAINER
  // ============================================================

  Widget _buildDropdownContainer({
    required Widget child,
    required double width,
  }) {
    return Material(
      color:
          Colors.transparent,

      child: Container(
        width: width,

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFF102F57,
          ).withOpacity(
            0.98,
          ),

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color:
                const Color(
              0xFF6B8DB5,
            ).withOpacity(
              0.35,
            ),

            width: 1,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(
                0.48,
              ),

              blurRadius: 28,

              spreadRadius: 1,

              offset:
                  const Offset(
                0,
                12,
              ),
            ),
          ],
        ),

        child: child,
      ),
    );
  }

  // ============================================================
  // CITY CARD
  // ============================================================

  Widget _buildCityCard(
    City city,
    int index,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        _selectCity(
          city.name,
        );
      },

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 300,
        ),

        curve:
            Curves.easeOut,

        // SAME CARD SIZE
        width: 250,
        height: 235,

        margin:
            const EdgeInsets
                .only(
          top: 5,
          bottom: 5,
        ),

        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            26,
          ),

          border:
              Border.all(
            color: isSelected
                ? const Color(
                    0xFF2D9CFF,
                  )
                : Colors.white
                    .withOpacity(
                  0.10,
                ),

            width:
                isSelected
                    ? 2
                    : 1,
          ),

          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(
                      0xFF168AFF,
                    ).withOpacity(
                      0.32,
                    )
                  : Colors.black
                      .withOpacity(
                      0.35,
                    ),

              blurRadius:
                  isSelected
                      ? 30
                      : 22,

              spreadRadius:
                  isSelected
                      ? 2
                      : 0,

              offset:
                  const Offset(
                0,
                12,
              ),
            ),
          ],
        ),

        clipBehavior:
            Clip.antiAlias,

        child: Stack(
          fit:
              StackFit.expand,

          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            if (city.image != null)
              Image.asset(
                city.image!,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _buildFallbackBackground(
                    city.name,
                  );
                },
              )
            else
              _buildFallbackBackground(
                city.name,
              ),

            // ==================================================
            // DARK GRADIENT
            // ==================================================

            Container(
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topCenter,

                  end:
                      Alignment.bottomCenter,

                  colors: [
                    Colors.transparent,
                    Color(0x10000000),
                    Color(0xE6000000),
                  ],

                  stops: [
                    0.25,
                    0.55,
                    1.0,
                  ],
                ),
              ),
            ),

            // ==================================================
            // NUMBER
            // ==================================================

            Positioned(
              top: 14,
              left: 14,

              child:
                  Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.black
                          .withOpacity(
                    0.42,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),

                  border:
                      Border.all(
                    color:
                        Colors.white
                            .withOpacity(
                      0.12,
                    ),
                  ),
                ),

                child:
                    Text(
                  '${(index + 1).toString().padLeft(2, '0')}',

                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withOpacity(
                      0.90,
                    ),

                    fontSize: 12,

                    fontWeight:
                        FontWeight.w700,

                    letterSpacing:
                        1,
                  ),
                ),
              ),
            ),

            // ==================================================
            // SELECTED CHECK
            // ==================================================

            if (isSelected)
              Positioned(
                top: 14,
                right: 14,

                child:
                    Container(
                  width: 32,
                  height: 32,

                  decoration:
                      const BoxDecoration(
                    shape:
                        BoxShape
                            .circle,

                    color:
                        Color(
                      0xFF2D9CFF,
                    ),
                  ),

                  child:
                      const Icon(
                    Icons
                        .check_rounded,

                    color:
                        Colors.white,

                    size: 19,
                  ),
                ),
              ),

            // ==================================================
            // CITY NAME + LOCATION
            // ==================================================

            Positioned(
              left: 18,
              right: 18,
              bottom: 18,

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    city.name,

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize: 23,

                      fontWeight:
                          FontWeight.w800,

                      letterSpacing:
                          -0.4,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .location_on_rounded,

                        size: 14,

                        color: Colors
                            .white
                            .withOpacity(
                          0.72,
                        ),
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Expanded(
                        child:
                            Text(
                          city.location,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            fontSize:
                                12.5,

                            color: Colors
                                .white
                                .withOpacity(
                              0.82,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FALLBACK BACKGROUND
  // ============================================================

  Widget _buildFallbackBackground(
    String cityName,
  ) {
    return Container(
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            Color(0xFF0D74D8),
            Color(0xFF083A78),
            Color(0xFF061C3D),
          ],
        ),
      ),

      child:
          Center(
        child: Icon(
          Icons
              .location_city_rounded,

          size: 70,

          color: Colors.white
              .withOpacity(
            0.18,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(
    int count,
  ) {
    final safePage =
        _currentPage.clamp(
      0,
      count - 1,
    );

    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .center,

      children:
          List.generate(
        count,
        (index) {
          final isActive =
              index == safePage;

          return AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),

            margin:
                const EdgeInsets
                    .symmetric(
              horizontal: 3,
            ),

            width:
                isActive
                    ? 24
                    : 7,

            height: 7,

            decoration:
                BoxDecoration(
              color: isActive
                  ? const Color(
                      0xFF2D9CFF,
                    )
                  : Colors.white
                      .withOpacity(
                      0.22,
                    ),

              borderRadius:
                  BorderRadius
                      .circular(
                20,
              ),
            ),
          );
        },
      ),
    );
  }
}