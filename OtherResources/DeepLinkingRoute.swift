import Foundation

enum DeepLinkingRoute {
    enum Navigate: String {
        case episode = "navigate/episode/:message"
        case movie = "navigate/movie/:message"
        case series = "navigate/series/:message"
        case seriesEpisode = "navigate/series/:message/season/:season_number/episode/:episode_number/:episode_name"
        case season = "navigate/series/:message/season/:season_number"
        case collection = "navigate/collection/:message"
        case offer = "navigate/offer/:message"
        case subscribe = "navigate/subscribe"

        case movieFromWeb = "*.com/movie/:message"
        case seriesFromWeb = "*.com/series/:message"
        case seasonFromWeb = "*.com/series/:message/season/:season_number"
        case episodeFromWeb = "*.com/series/:message/season/:season_number/episode/:episode_number/:episode_name"

        case activate = "navigate/activate/:message"
    }

    enum Play: String {
        case episode = "play/episode/:message"
        case movie = "play/movie/:message"
        case movieTrailer = "play/movie/:message/trailer"
        case extra = "play/extra/:message"
        case series = "play/series/:message"
        case seriesEpisode = "play/series/:message/season/:season_number/episode/:episode_number/:episode_name"
        case seriesTrailer = "play/series/:message/trailer"
        case season = "play/series/:message/season/:season_number"
    }

    enum Queue: String {
        case episode = "queue/add/episode/:message"
        case movie = "queue/add/movie/:message"
    }

    enum AppSection: String {
        case queue = "navigate/app_section/queue"
        case myList = "navigate/app_section/my_list"
        case downloads = "navigate/app_section/downloads"
        case settings = "navigate/app_section/settings"
        case help = "navigate/app_section/help"
        case connect = "navigate/app_section/connect"
        case search = "navigate/app_section/search"
        case startup = "navigate/app_section/startup"
        case home = "navigate/app_section/home"
        case movies = "navigate/app_section/movies"
        case moviesGenre = "navigate/app_section/movies/:genre_short_name"
        case originals = "navigate/app_section/originals"
        case originalsCategory = "navigate/app_section/originals/:category"
        case liveTV = "navigate/app_section/live_tv"
    }

    enum LiveTV: String {
        case mainPage = "navigate/live"
        case channel = "navigate/live/:message"
    }

    enum Push: String {
        case enable = "enable_push"
    }
}
