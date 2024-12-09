//
//  PagedInfiniteScrollView.swift
//  InfinitePageView
//
//  Created by beader on 2023/4/19.
//

import SwiftUI
import UIKit


struct IdentifiableContent<C: View>: View {
    let index: Int
    let content: C

    init(index: Int, @ViewBuilder content: () -> C) {
        self.index = index
        self.content = content()
    }

    var body: some View {
        content
    }
}

class Props<Content: View> {
    @Binding var currentPage: Int
    var content: (Int) -> Content
    var onPageAppear: (@MainActor (Int, UIPageViewController.NavigationDirection) -> Void)?
    var onPageDisappear: (@MainActor (Int, UIPageViewController.NavigationDirection) -> Void)?
    var onPageWillAppear: (@MainActor (Int, UIPageViewController.NavigationDirection) -> Void)?
    var nextPage: ((Int) -> Int?)?
    var prevPage: ((Int) -> Int?)?
    
    init(
        currentPage: Binding<Int>,
        content: @escaping (Int) -> Content,
        onPageAppear: ((Int, UIPageViewController.NavigationDirection) -> Void)?,
        onPageDisappear: ((Int, UIPageViewController.NavigationDirection) -> Void)?,
        onPageWillAppear: ((Int, UIPageViewController.NavigationDirection) -> Void)?,
        nextPage: ((Int) -> Int?)?,
        prevPage: ((Int) -> Int?)?) {
        self._currentPage = currentPage
        self.content = content
        self.onPageAppear = onPageAppear
        self.onPageDisappear = onPageDisappear
        self.onPageWillAppear = onPageWillAppear
        self.nextPage = nextPage
        self.prevPage = prevPage
    }
}

public struct PagedInfiniteScrollView<Content: View>: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIPageViewController

    let props: Props<Content>
    let navigationOrientation: UIPageViewController.NavigationOrientation

    public init(currentPage: Binding<Int>,
         navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal,
         @ViewBuilder content: @escaping (Int) -> Content,
         nextPage: ((Int) -> Int?)? = nil,
        prevPage: ((Int) -> Int?)? = nil,
         onPageAppear: ((Int, UIPageViewController.NavigationDirection) -> Void)? = nil,
         onPageDisappear: ((Int, UIPageViewController.NavigationDirection) -> Void)? = nil,
         onPageWillAppear: ((Int, UIPageViewController.NavigationDirection) -> Void)? = nil
    ) {
        props = Props(currentPage: currentPage,
                      content: content,
                      onPageAppear: onPageAppear,
                      onPageDisappear: onPageDisappear,
                      onPageWillAppear: onPageWillAppear,
                      nextPage: nextPage,
                      prevPage: prevPage)
        self.navigationOrientation = navigationOrientation
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(props)
    }

    public func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: navigationOrientation)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        let initialViewController = UIHostingController(rootView: IdentifiableContent(index: props.currentPage, content: { props.content(props.currentPage) }))
        initialViewController.view.backgroundColor = .clear
        pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
        
        Task { @MainActor in
            // Initial page will not trigger willTransitionTo delegate method
            props.onPageWillAppear?(props.currentPage, .forward)
            props.onPageAppear?(props.currentPage, .forward)
        }

        return pageViewController
    }

    public func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        guard let currentViewController = uiViewController.viewControllers?.first as? UIHostingController<IdentifiableContent<Content>> else {
            return
        }
        let currentIndex = currentViewController.rootView.index

        context.coordinator.props = props
        
        infoLog("updateViewController", currentIndex, props.currentPage)
        
        if context.coordinator.inTransition {
            currentViewController.rootView = IdentifiableContent(index: currentIndex, content: { props.content(currentIndex) })
            
        } else if props.currentPage != currentIndex {
            let direction: UIPageViewController.NavigationDirection = props.currentPage > currentIndex ? .forward : .reverse
            
            let newViewController = UIHostingController(rootView: IdentifiableContent(index: props.currentPage, content: { props.content(props.currentPage) }))
            newViewController.view.backgroundColor = .clear
            uiViewController.setViewControllers([newViewController], direction: direction, animated: true, completion: nil)
            // Page change triggered by `currentPage` binding will not trigger willTransitionTo delegate method
            Task { @MainActor in
                props.onPageWillAppear?(props.currentPage, direction)
                props.onPageDisappear?(currentIndex, direction)
                props.onPageAppear?(props.currentPage, direction)
            }
        } else {
            currentViewController.rootView = IdentifiableContent(index: props.currentPage, content: { props.content(props.currentPage) })
        }
    }

    @MainActor
    public class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var props: Props<Content>
        var inTransition = false

        init(_ props: Props<Content>) {
            self.props = props
        }

        public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let currentView = viewController as? UIHostingController<IdentifiableContent<Content>>, let currentIndex = currentView.rootView.index as Int? else {
                return nil
            }

            guard let previousIndex = props.prevPage?(currentIndex) else {
                return nil
            }

            let vc = UIHostingController(rootView: IdentifiableContent(index: previousIndex, content: { props.content(previousIndex) }))
            vc.view.backgroundColor = .clear
            return vc
        }

        public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let currentView = viewController as? UIHostingController<IdentifiableContent<Content>>, let currentIndex = currentView.rootView.index as Int? else {
                return nil
            }

            guard let nextIndex = props.nextPage?(currentIndex) else {
                return nil
            }

            let vc = UIHostingController(rootView: IdentifiableContent(index: nextIndex, content: { props.content(nextIndex) }))
            vc.view.backgroundColor = .clear
            return vc
        }
        
        public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
            infoLog("willTransitionTo")
            inTransition = true
            if let pendingView = pendingViewControllers.first as? UIHostingController<IdentifiableContent<Content>>,
               let currentView = pageViewController.viewControllers?.first as? UIHostingController<IdentifiableContent<Content>>,
               let pendingIndex = pendingView.rootView.index as Int?,
               let currentIndex = currentView.rootView.index as Int?
            {
                let direction: UIPageViewController.NavigationDirection =
                    pendingIndex > currentIndex ? .forward : .reverse
                
                props.onPageWillAppear?(pendingIndex, direction)
            }
        }

        public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            infoLog("didFinishAnimating \(finished), transitionCompleted \(completed) ")
            inTransition = false
            guard completed else {
                return
            }
            
            let previousView = previousViewControllers.first as? UIHostingController<IdentifiableContent<Content>>
            let previousIndex = previousView?.rootView.index as Int?
            let currentView = pageViewController.viewControllers?.first as? UIHostingController<IdentifiableContent<Content>>
            let currentIndex = currentView?.rootView.index as Int?
            let direction: UIPageViewController.NavigationDirection =
            switch (previousIndex, currentIndex) {
            case (let previousIndex?, let currentIndex?):
                currentIndex > previousIndex ? .forward : .reverse
            case (nil, _?):
                    .forward
            default:
                    .reverse
            }
            
            if let currentIndex {
                infoLog("set currentPage from pageview", currentIndex)
                props.currentPage = currentIndex
                props.onPageAppear?(currentIndex, direction)
            }
            
            if let previousIndex {
                props.onPageDisappear?(previousIndex, direction)
            }
        }
    }
}

fileprivate struct ContentView: View {
    @State private var currentPage: Int = 0
    @State var data = ["a", "b", "c", "d"]

    var body: some View {
        VStack {
            PagedInfiniteScrollView(currentPage: $currentPage, navigationOrientation: .horizontal) { page in
                Text("\(data[page])")
                        .font(.largeTitle)
                        .edgesIgnoringSafeArea(.all)
            } nextPage: { i in
                i <= 3 ? i + 1 : nil
            } prevPage: { i in
                i > 0 ? i - 1 : nil
            } onPageAppear: { page, _ in
                print("Page \(page) appeared")
            } onPageDisappear: { page, _ in
                print("Page \(page) disappeared")
            } onPageWillAppear: { page, _ in
                print("Page \(page) will appear")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)

            HStack {
                Button(action: {
                    currentPage -= 1
                }) {
                    Text("Previous")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)

                Button(action: {
                    currentPage += 1
                }) {
                    Text("Next")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            }
            .padding(.bottom, 16)
        }
    }
}


#Preview {
    ContentView()
}
