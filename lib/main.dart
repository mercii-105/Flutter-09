import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ApiExplorerApp());
}

class ApiExplorerApp extends StatelessWidget {
  const ApiExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'API Explorer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7661A8)),
        scaffoldBackgroundColor: const Color(0xFFF7F4FC),
      ),
      home: const ApiHomePage(),
    );
  }
}

class ApiHomePage extends StatefulWidget {
  const ApiHomePage({super.key});

  @override
  State<ApiHomePage> createState() => _ApiHomePageState();
}

class _ApiHomePageState extends State<ApiHomePage> {
  List<dynamic> posts = [];

  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  static const String apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fetch posts using HTTP GET
  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          posts = data;
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to fetch posts. Please check your internet connection.';
        isLoading = false;
      });
    }
  }

  // Filter posts using the search input
  List<dynamic> get filteredPosts {
    return posts.where((post) {
      final title = post['title'].toString().toLowerCase();

      final body = post['body'].toString().toLowerCase();

      final query = searchQuery.toLowerCase().trim();

      return title.contains(query) || body.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = filteredPosts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'API Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEAE3F7),
        actions: [
          IconButton(
            tooltip: 'Refresh posts',
            onPressed: isLoading ? null : fetchData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          // Dashboard header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7661A8), Color(0xFFAA8BCB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REST API • HTTP GET',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explore API Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${posts.length} posts retrieved from the server',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        color: Colors.white70,
                        size: 17,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'JSONPlaceholder API',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search posts by title or content...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Posts heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Posts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('${visiblePosts.length} found'),
              ],
            ),
          ),

          // Posts list, loading and error states
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text('Loading posts...'),
                      ],
                    ),
                  )
                : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 45,
                          ),
                          const SizedBox(height: 12),
                          Text(errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: fetchData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchData,
                    child: visiblePosts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 70),
                              Center(child: Text('No matching posts found.')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: visiblePosts.length,
                            itemBuilder: (context, index) {
                              final post = visiblePosts[index];

                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 13),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(
                                              0xFFEAE3F7,
                                            ),
                                            child: Text(
                                              '${post['id']}',
                                              style: const TextStyle(
                                                color: Color(0xFF65508F),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'POST #${post['id']}',
                                            style: const TextStyle(
                                              color: Color(0xFF7661A8),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        post['title'].toString(),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        post['body'].toString(),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'User ID: ${post['userId']}',
                                        style: const TextStyle(
                                          color: Color(0xFF7661A8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
