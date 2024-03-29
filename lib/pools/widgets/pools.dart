import 'package:e305/client/models/pool.dart';
import 'package:e305/interface/widgets/appbar.dart';
import 'package:e305/interface/widgets/loading.dart';
import 'package:e305/pools/data/controller.dart';
import 'package:e305/pools/widgets/reader.dart';
import 'package:e305/pools/widgets/tile.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PoolPage extends StatefulWidget {
  PoolPage();

  @override
  _PoolPageState createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> {
  bool searching = false;
  PoolController controller = PoolController();
  ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  PreferredSizeWidget appBar() {
    return ScrollToTopAppBar(
      controller: scrollController,
      builder: (context, gesture) => SearchableAppBar(
        label: 'Title',
        title: gesture(context, Text('Pools')),
        getSearch: () => controller.search.value,
        setSearch: (value) => controller.search.value = value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: SmartRefresher(
        primary: false,
        scrollController: scrollController,
        controller: controller.refreshController,
        onRefresh: () => controller.refresh(background: true),
        header: ClassicHeader(
          refreshingIcon: OrbitLoadingIndicator(size: 40),
        ),
        child: PagedListView(
          physics: BouncingScrollPhysics(),
          pagingController: controller,
          builderDelegate: PagedChildBuilderDelegate<Pool>(
            itemBuilder: (context, item, index) => PoolTile(
              pool: item,
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => PoolReader(pool: item),
                ),
              ),
            ),
            firstPageProgressIndicatorBuilder: (context) => Center(
              child: OrbitLoadingIndicator(size: 100),
            ),
            newPageProgressIndicatorBuilder: (context) => Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: PulseLoadingIndicator(size: 60)),
            ),
          ),
        ),
      ),
    );
  }
}
