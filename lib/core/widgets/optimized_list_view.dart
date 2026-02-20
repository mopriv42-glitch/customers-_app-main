import 'package:flutter/material.dart';

/// Optimized ListView with performance improvements
class OptimizedListView extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? loadingWidget;
  final double cacheExtent;
  final int? semanticChildCount;

  const OptimizedListView({
    Key? key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.loadingWidget,
    this.cacheExtent = 250.0, // Increased cache for better performance
    this.semanticChildCount,
  }) : super(key: key);

  @override
  State<OptimizedListView> createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();

    if (widget.onLoadMore != null) {
      _scrollController.addListener(_scrollListener);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_scrollListener);
    }
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more at 80% scroll

    if (currentScroll >= threshold &&
        widget.hasMore &&
        !widget.isLoading &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      widget.onLoadMore?.call();

      // Reset loading state after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final children = <Widget>[...widget.children];

    // Add loading indicator if needed
    if (widget.hasMore && widget.isLoading) {
      children.add(widget.loadingWidget ?? _buildDefaultLoadingWidget());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent,
      semanticChildCount: widget.semanticChildCount ?? children.length,
      itemCount: children.length,
      itemBuilder: (context, index) {
        if (index < children.length) {
          return children[index];
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Optimized ListView.separated with performance improvements
class OptimizedListViewSeparated extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? loadingWidget;
  final double cacheExtent;

  const OptimizedListViewSeparated({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.loadingWidget,
    this.cacheExtent = 250.0,
  }) : super(key: key);

  @override
  State<OptimizedListViewSeparated> createState() =>
      _OptimizedListViewSeparatedState();
}

class _OptimizedListViewSeparatedState extends State<OptimizedListViewSeparated>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();

    if (widget.onLoadMore != null) {
      _scrollController.addListener(_scrollListener);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_scrollListener);
    }
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold &&
        widget.hasMore &&
        !widget.isLoading &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      widget.onLoadMore?.call();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    int totalItemCount = widget.itemCount;
    if (widget.hasMore && widget.isLoading) {
      totalItemCount += 1; // Add loading item
    }

    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent,
      itemCount: totalItemCount,
      separatorBuilder: (context, index) {
        if (index < widget.itemCount - 1) {
          return widget.separatorBuilder(context, index);
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        if (index < widget.itemCount) {
          return widget.itemBuilder(context, index);
        } else if (widget.hasMore && widget.isLoading) {
          return widget.loadingWidget ?? _buildDefaultLoadingWidget();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
