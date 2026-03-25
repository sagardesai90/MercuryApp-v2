//
//  TutorialViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pages :[UIViewController]!
    var pageControl :UIPageControl? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        pages = [
            AppController.instantiate(id: "turorial1"),
            AppController.instantiate(id: "turorial2"),
            AppController.instantiate(id: "turorial3"),
            AppController.instantiate(id: "turorial4"),
            AppController.instantiate(id: "turorial5")
        ];
        
        if let firstViewController = self.pages.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        
        pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.height*0.395,width: UIScreen.main.bounds.width,height: 25))
        pageControl?.isUserInteractionEnabled = false
        self.pageControl?.numberOfPages = self.pages.count
        self.pageControl?.currentPage = 0
        self.view.addSubview(pageControl!)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let viewControllerIndex = self.pages.firstIndex(of: viewController)
        let previousIndex = viewControllerIndex! - 1
        return (previousIndex == -1) ? nil : self.pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let viewControllerIndex = self.pages.firstIndex(of: viewController)
        let nextIndex = viewControllerIndex! + 1
        return (nextIndex == self.pages.count) ? nil : self.pages[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl?.currentPage = self.pages.firstIndex(of: pageContentViewController)!
    }

}
