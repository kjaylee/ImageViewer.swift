import UIKit

public protocol ImageDataSource: AnyObject {
    func numberOfImages() -> Int
    func imageItem(at index:Int) -> ImageItem
}

public class ImageCarouselViewController:UIPageViewController, ImageViewerTransitionViewControllerConvertible {
    public var currentIndex: Int {
        guard let vc = self.viewControllers?.first as? ImageViewerController else {
            return 0
        }
        return vc.index
    }
    
    unowned var initialSourceView: UIImageView?
    var sourceView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return initialIndex == vc.index ? initialSourceView : nil
    }
    
    var targetView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return vc.imageView
    }
    
    var navigationContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    weak var imageDatasource:ImageDataSource?
    let imageLoader:ImageLoader
 
    var initialIndex = 0
    
    var theme:ImageViewerTheme = .light {
        didSet {
            navigationContainer.backgroundColor = theme.navigationColor
            backgroundView?.backgroundColor = theme.backgroundColor
        }
    }
    
    var imageContentMode: UIView.ContentMode = .scaleAspectFill
    var options:[ImageViewerOption] = []
    
    private var onRightNavBarTapped:((Int) -> Void)?
    private(set) lazy var backgroundView:UIView? = {
        let _v = UIView()
        _v.backgroundColor = theme.backgroundColor
        _v.alpha = 1.0
        return _v
    }()
    private let imageViewerPresentationDelegate: ImageViewerTransitionPresentationManager
    
    public init(
        sourceView:UIImageView,
        imageDataSource: ImageDataSource?,
        imageLoader: ImageLoader,
        options:[ImageViewerOption] = [],
        initialIndex:Int = 0) {
        
        self.initialSourceView = sourceView
        self.initialIndex = initialIndex
        self.options = options
        self.imageDatasource = imageDataSource
        self.imageLoader = imageLoader
        let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]
        
        var _imageContentMode = imageContentMode
        options.forEach {
            switch $0 {
            case .contentMode(let contentMode):
                _imageContentMode = contentMode
            default:
                break
            }
        }
        imageContentMode = _imageContentMode
        
        self.imageViewerPresentationDelegate = ImageViewerTransitionPresentationManager(imageContentMode: imageContentMode)
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: pageOptions)
        
        transitioningDelegate = imageViewerPresentationDelegate
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addNavigationBar() {
        let v = navigationContainer
        view.addSubview(v)
        v.backgroundColor = .magenta
        // 오토리사이징 마스크 비활성화
        v.translatesAutoresizingMaskIntoConstraints = false
        // 오토레이아웃 제약조건 설정
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: view.topAnchor),
            v.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)
         ])
    }
    
    private func addBackgroundView() {
        guard let backgroundView = backgroundView else { return }
        view.addSubview(backgroundView)
        backgroundView.bindFrameToSuperview()
        view.sendSubviewToBack(backgroundView)
    }
    
    private func applyOptions() {
        
        options.forEach {
            switch $0 {
            case .theme(let theme):
                self.theme = theme
            case .contentMode(let contentMode):
                self.imageContentMode = contentMode
            case .navigationTitleView(let view):
                navigationContainer.addSubview(view)
                // 오토리사이징 마스크 비활성화
                view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    view.heightAnchor.constraint(equalToConstant: 44.0),
                    navigationContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    navigationContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    navigationContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
            case .initialized(let action):
                action()
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        addBackgroundView()
        addNavigationBar()
        applyOptions()
        dataSource = self
        if let imageDatasource = imageDatasource {
            let initialVC:ImageViewerController = .init(
                index: initialIndex,
                imageItem: imageDatasource.imageItem(at: initialIndex),
                imageLoader: imageLoader)
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }

    @objc
    private func dismiss(_ sender:UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        initialSourceView?.alpha = 1.0
    }
    
    @objc
    func diTapRightNavBarItem(_ sender:UIBarButtonItem) {
        guard let onTap = onRightNavBarTapped,
            let _firstVC = viewControllers?.first as? ImageViewerController
            else { return }
        onTap(_firstVC.index)
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        if theme == .dark {
            return .lightContent
        }
        return .default
    }
}

extension ImageCarouselViewController:UIPageViewControllerDataSource {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        guard vc.index > 0 else { return nil }
 
        let newIndex = vc.index - 1
        return ImageViewerController.init(
            index: newIndex,
            imageItem:  imageDatasource.imageItem(at: newIndex),
            imageLoader: vc.imageLoader)
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        guard vc.index <= (imageDatasource.numberOfImages() - 2) else { return nil }
        
        let newIndex = vc.index + 1
        return ImageViewerController.init(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex),
            imageLoader: vc.imageLoader)
    }
}
