import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../widgets/movie_page.dart';
import '../utils/fetch_data.dart';
import '../utils/data_structure.dart';
import '../widgets/search_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cache_data/cachedata.dart';
import 'package:tracker/utils/data_function.dart';

// 这里使用了GetX状态库，不然无限滚动实现不了，太难了
class Controller extends GetxController {
  ScrollController scrollController = ScrollController();
  List<SingleMovie> movieData = [];
  var isLoading = false;
  int _page = 1;

  void getMovieDataReady() {
    movieData = cache_data.getInstance().MovieData;
  }

  int movieDataLength() {
    update();
    int moviedataLength = 0;
    moviedataLength = movieData.length + (isLoading ? 1 : 0);
    return moviedataLength;
  }

  void loadMore() {
    // 当监测到划到最底部时，加载下一个page
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !isLoading) {
      isLoading = true;
      update();
      fetchDiscoverData(_page + 1).then((value) {
        // 新数据和旧数据的拼接
        movieData.addAll(value);
        // 增加新的页面
        _page++;
        isLoading = false;
        update();
      }).catchError((error) {
        debugPrint('发生错误：$error');
      });
    }
  }

  static Controller get to => Get.find();

  @override
  // 这是页面一打开就会运行的函数
  void onInit() {
    getMovieDataReady();
    scrollController = ScrollController();
    isLoading = false;
    // 添加滚动监听器
    scrollController.addListener(loadMore);
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
            child: SearchBar(
              hintText: '搜索你的电影',
              leading:
                  const Icon(Icons.search, color: Colors.deepPurple), // 调整图标颜色
              onTap: () {
                Get.to(() => const SearchBarView(),
                    transition: Transition.fade);
              },
            ),
          ),
          const SizedBox(height: 20), // 添加适当的间距
          Expanded(
            child: GetBuilder<Controller>(
              init: Controller(),
              builder: (controller) {
                return MasonryGridView.count(
                  controller: controller.scrollController,
                  crossAxisCount: 2,
                  itemCount: controller.movieDataLength(),
                  itemBuilder: (context, index) {
                    if (index < controller.movieData.length) {
                      // 单个电影卡片，传入一个singleMovie变量
                      return MovieCard(movie: controller.movieData[index]);
                    } else {
                      // 加载转圈圈的进度条
                      return const LoadingView();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 加载转圈圈的进度条
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: Center(
        child: SizedBox(
          width: 18.0,
          height: 18.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey,
            ),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

// 生成电影卡片的界面
// TODO: 美化
class MovieCard extends StatelessWidget {
  SingleMovie movie;

  MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点击就导航到MoviePage
      onTap: () async {
        await createTables(movie); //创建改电影的所有表，到本地media.db,有些列初始为空，待update
        Get.to(() => MoviePage(movie: movie), transition: Transition.fadeIn);
      },
      // 一个电影美化过的卡片
      child: Card(
        elevation: 10, // 抬起的阴影
        clipBehavior: Clip.antiAlias, // 设置抗锯齿
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ), // 设置圆角
        margin: const EdgeInsets.all(8),
        child: Stack(
          textDirection: TextDirection.rtl,
          fit: StackFit.loose,
          alignment: Alignment.bottomLeft,
          children: <Widget>[
            // 获取网络图片并缓存，
            CachedNetworkImage(
              imageUrl: "https://image.tmdb.org/t/p/w500/${movie.posterPath}",
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  CircularProgressIndicator(value: downloadProgress.progress),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(5, 50, 5, 10),
              // 设置阴影
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    movie.title!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'TMDB评分：${movie.voteAverage} (${movie.voteCount})',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
