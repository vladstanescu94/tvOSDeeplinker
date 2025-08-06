import Foundation

protocol DeepLinkRouterDelegate: AnyObject {
    func navigateToMovie(identifier: String)
    func navigateToSeries(identifier: String, seasonNumber: String?)
    func navigateToEpisode(identifier: String)
    func navigateToCollection(identifier: String)

    func navigateToSettings()
    func navigateToHelp()
    func navigateToConnectTV()
    func navigateToSearch()
    func navigateToDownloads()
    func navigateToMyList()
    func navigateToHome()
    func navigateToStartup()
    func navigateToOriginals(category: String?)
    func navigateToMovies(genre: String?)
    func navigateToOffer(identifier: String)
    func navigateToChooseYourPlan()

    func navigateToActivateTV(code: String?)

    func playEpisode(identifier: String)
    func playMovie(identifier: String)
    func playMovieTrailer(identifier: String)
    func playExtra(identifier: String)
    func playSeries(identifier: String, seasonNumber: String?)
    func playSeriesTrailer(identifier: String)

    func queueEpisode(identifier: String)
    func queueMovie(identifier: String)

    func navigateToLiveTV()
    func navigateToLiveTV(toChannel channel: String)

    func navigateToSeriesAndPlayEpisode(seriesIdentifier: String, mediaIdentifier: String)

    func enablePush()
}

final class DeepLinkRouter {
    private var router: DPLDeepLinkRouter?

    weak var delegate: DeepLinkRouterDelegate?

    init() {
        self.router = DPLDeepLinkRouter()
        self.registerRouterActions()
    }

    func handle(url: URL) {
        self.router?.handle(url, withCompletion: { _, _ in })
    }

    // MARK: - Routes parsers

    private func registerRouterActions() {
        self.registerRouterNavigationActions()
        self.registerRouterPlayActions()
        self.registerRouterQueueActions()
        self.registerLiveTVActions()
        self.registerPushActions()
        self.registerDefaultRedirect()
    }

    // swiftlint:disable cyclomatic_complexity function_body_length

    private func registerRouterNavigationActions() {
        guard let router = self.router else {
            return
        }

        router.register(DeepLinkingRoute.Navigate.subscribe.rawValue) { [weak self] _ in
            guard let self else { return }

            self.delegate?.navigateToChooseYourPlan()
        }

        router.register(DeepLinkingRoute.Navigate.activate.rawValue) { [weak self] link in
            guard let self else { return }

            if let activationCode = link.routeParameters["message"] as? String {
                self.delegate?.navigateToActivateTV(code: activationCode)
            }
        }

        router.register(DeepLinkingRoute.Navigate.movie.rawValue) { [weak self] link in
            guard let self else { return }

            if let movieId = link.routeParameters["message"] as? String {
                self.delegate?.navigateToMovie(identifier: movieId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .movie, contentId: movieId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.movieFromWeb.rawValue) { [weak self] link in
            guard let self else { return }

            if let movieId = link.routeParameters["message"] as? String {
                if let isPlay = link.queryParameters["play"] as? String, isPlay == "true" {
                    self.delegate?.playMovie(identifier: movieId)
                } else {
                    self.delegate?.navigateToMovie(identifier: movieId)
                }
                self.logContentRedirect(link: link.url.absoluteString, contentType: .movie, contentId: movieId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.seriesFromWeb.rawValue) { [weak self] link in
            guard let self else { return }

            if let seriesId = link.routeParameters["message"] as? String {
                if let isPlay = link.queryParameters["play"] as? String, isPlay == "true" {
                    self.delegate?.playSeries(identifier: seriesId, seasonNumber: nil)
                } else {
                    self.delegate?.navigateToSeries(identifier: seriesId, seasonNumber: nil)
                }
                self.logContentRedirect(link: link.url.absoluteString, contentType: .series, contentId: seriesId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.series.rawValue) { [weak self] link in
            guard let self else { return }

            if let seriesId = link.routeParameters["message"] as? String {
                self.delegate?.navigateToSeries(identifier: seriesId, seasonNumber: nil)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .series, contentId: seriesId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.seriesEpisode.rawValue) { [weak self] link in
            guard let self else { return }

            if let seriesId = link.routeParameters["message"] as? String, let seasonNumber = link.routeParameters["season_number"] as? String {
                self.delegate?.navigateToSeries(identifier: seriesId, seasonNumber: seasonNumber)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .series, contentId: seriesId)
            }
        }

        router.register(DeepLinkingRoute.Play.seriesEpisode.rawValue) { [weak self] link in
            guard let self else { return }

            if let seriesId = link.routeParameters["message"] as? String, let episodeId = link.routeParameters["episode_name"] as? String {
                self.delegate?.navigateToSeriesAndPlayEpisode(seriesIdentifier: seriesId, mediaIdentifier: episodeId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .episode, contentId: episodeId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.episodeFromWeb.rawValue) { [weak self] link in
            guard let self else { return }
            if let episodeId = link.routeParameters["episode_name"] as? String {
                if let isPlay = link.queryParameters["play"] as? String, isPlay == "true" {
                    self.delegate?.playEpisode(identifier: episodeId)
                } else {
                    self.delegate?.navigateToEpisode(identifier: episodeId)
                }
                self.logContentRedirect(link: link.url.absoluteString, contentType: .episode, contentId: episodeId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.episode.rawValue) { [weak self] link in
            guard let self else { return }
            if let episodeId = link.routeParameters["message"] as? String {
                self.delegate?.navigateToEpisode(identifier: episodeId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .episode, contentId: episodeId)
            }
        }

        router.register(DeepLinkingRoute.Navigate.season.rawValue) { [weak self] link in
            guard let self else { return }
            if let seriesID = link.routeParameters["message"] as? String,
               let seasonNumber = link.routeParameters["season_number"] as? String
            {
                self.delegate?.navigateToSeries(identifier: seriesID, seasonNumber: seasonNumber)
            }
        }

        router.register(DeepLinkingRoute.Navigate.seasonFromWeb.rawValue) { [weak self] link in
            guard let self else { return }
            if let seriesID = link.routeParameters["message"] as? String,
               let seasonNumber = link.routeParameters["season_number"] as? String
            {
                if let isPlay = link.queryParameters["play"] as? String, isPlay == "true" {
                    self.delegate?.playSeries(identifier: seriesID, seasonNumber: seasonNumber)
                } else {
                    self.delegate?.navigateToSeries(identifier: seriesID, seasonNumber: seasonNumber)
                }
            }
        }

        router.register(DeepLinkingRoute.Navigate.collection.rawValue) { [weak self] link in
            guard let self else { return }
            if let collectionID = link.routeParameters["message"] as? String {
                self.delegate?.navigateToCollection(identifier: collectionID)
            }
        }

        router.register(DeepLinkingRoute.Navigate.offer.rawValue) { [weak self] link in
            guard let self else { return }
            if let offerID = link.routeParameters["message"] as? String {
                self.delegate?.navigateToOffer(identifier: offerID)
            }
        }

        router.register(DeepLinkingRoute.AppSection.queue.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToMyList()
        }

        router.register(DeepLinkingRoute.AppSection.myList.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToMyList()
        }

        router.register(DeepLinkingRoute.AppSection.downloads.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToDownloads()
        }

        router.register(DeepLinkingRoute.AppSection.settings.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToSettings()
        }

        router.register(DeepLinkingRoute.AppSection.help.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToHelp()
        }

        router.register(DeepLinkingRoute.AppSection.connect.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToConnectTV()
        }

        router.register(DeepLinkingRoute.AppSection.search.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToSearch()
        }

        router.register(DeepLinkingRoute.AppSection.startup.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToStartup()
        }

        router.register(DeepLinkingRoute.AppSection.home.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToHome()
        }

        router.register(DeepLinkingRoute.AppSection.movies.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToMovies(genre: nil)
        }

        router.register(DeepLinkingRoute.AppSection.moviesGenre.rawValue) { [weak self] link in
            guard let self else { return }

            if let genreShortName = link.routeParameters["genre_short_name"] as? String {
                self.delegate?.navigateToMovies(genre: genreShortName)
            }
        }

        router.register(DeepLinkingRoute.AppSection.originals.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToOriginals(category: nil)
        }

        router.register(DeepLinkingRoute.AppSection.originalsCategory.rawValue) { [weak self] link in
            guard let self else { return }

            if let originalsCategory = link.routeParameters["category"] as? String {
                self.delegate?.navigateToOriginals(category: originalsCategory)
            }
        }

        router.register(DeepLinkingRoute.AppSection.liveTV.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToLiveTV()
        }
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    private func registerRouterPlayActions() {
        guard let router = self.router else {
            return
        }

        router.register(DeepLinkingRoute.Play.movie.rawValue) { [weak self] link in
            guard let self else { return }
            if let movieId = link.routeParameters["message"] as? String {
                self.delegate?.playMovie(identifier: movieId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .movie, contentId: movieId)
            }
        }

        router.register(DeepLinkingRoute.Play.movieTrailer.rawValue) { [weak self] link in
            if let movieId = link.routeParameters["message"] as? String {
                self?.delegate?.playMovieTrailer(identifier: movieId)
                self?.logContentRedirect(link: link.url.absoluteString, contentType: .movie, contentId: movieId)
            }
        }

        router.register(DeepLinkingRoute.Play.episode.rawValue) { [weak self] link in
            guard let self else { return }
            if let episodeId = link.routeParameters["message"] as? String {
                self.delegate?.playEpisode(identifier: episodeId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .episode, contentId: episodeId)
            }
        }

        router.register(DeepLinkingRoute.Play.extra.rawValue) { [weak self] link in
            guard let self else { return }
            if let extraId = link.routeParameters["message"] as? String {
                self.delegate?.playExtra(identifier: extraId)
            }
        }

        router.register(DeepLinkingRoute.Play.series.rawValue) { [weak self] link in
            guard let self else { return }
            if let seriesId = link.routeParameters["message"] as? String {
                self.delegate?.playSeries(identifier: seriesId, seasonNumber: nil)
            }
        }

        router.register(DeepLinkingRoute.Play.seriesTrailer.rawValue) { [weak self] link in
            guard let self else { return }
            if let seriesId = link.routeParameters["message"] as? String {
                self.delegate?.playSeriesTrailer(identifier: seriesId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .series, contentId: seriesId)
            }
        }

        router.register(DeepLinkingRoute.Play.season.rawValue) { [weak self] link in
            guard let self else { return }
            if let seriesId = link.routeParameters["message"] as? String,
               let seasonNumber = link.routeParameters["season_number"] as? String
            {
                self.delegate?.playSeries(identifier: seriesId, seasonNumber: seasonNumber)
            }
        }
    }

    private func registerRouterQueueActions() {
        guard let router = self.router else {
            return
        }

        router.register(DeepLinkingRoute.Queue.movie.rawValue) { [weak self] link in
            guard let self else { return }
            if let movieId = link.routeParameters["message"] as? String {
                self.delegate?.queueMovie(identifier: movieId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .movie, contentId: movieId)
            }
        }

        router.register(DeepLinkingRoute.Queue.episode.rawValue) { [weak self] link in
            guard let self else { return }
            if let episodeId = link.routeParameters["message"] as? String {
                self.delegate?.queueEpisode(identifier: episodeId)
                self.logContentRedirect(link: link.url.absoluteString, contentType: .episode, contentId: episodeId)
            }
        }
    }

    private func registerDefaultRedirect() {
        // Any failed deep-links should take the user to the home screen
        // If the link is a web link, open web browser
        self.router?.register(".*", routeHandlerBlock: { [weak self] link in
            guard let self else { return }
            let redirectURL = link.url

            if redirectURL.absoluteString.contains("http"),
               UIApplication.shared.canOpenURL(redirectURL)
            {
                UIApplication.shared.open(redirectURL, options: [:], completionHandler: nil)
            }

            self.delegate?.navigateToHome()
        })
    }

    private func registerLiveTVActions() {
        guard let router = self.router else {
            return
        }

        router.register(DeepLinkingRoute.LiveTV.mainPage.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.navigateToLiveTV()
        }

        router.register(DeepLinkingRoute.LiveTV.channel.rawValue) { [weak self] link in
            guard let self else { return }
            if let channel = link.routeParameters["message"] as? String {
                self.delegate?.navigateToLiveTV(toChannel: channel)
            }
        }
    }

    private func registerPushActions() {
        guard let router = self.router else {
            return
        }

        router.register(DeepLinkingRoute.Push.enable.rawValue) { [weak self] _ in
            guard let self else { return }
            self.delegate?.enablePush()
        }
    }

    // MARK: - Tracking

    func logContentRedirect(link: String, contentType: CollectionItemType, contentId: String) {
        let event = DeeplinkEvent(deepLink: link,
                                  selectedMediaType: contentType,
                                  contentId: contentId)
        AnalyticsManager.shared.log(event)
    }
}
