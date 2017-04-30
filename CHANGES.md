## 0.2.1 - 2017/04/30

1. update @flatten/array dep
2. return `control` in the "executor"
3. clarify code choosing start node in Control, and, accept it from the options
4. reuse the `next` alias in the lower code

## 0.2.0 - 2017/04/29

1. revise implementation to eliminate coffeescript splats on arguments because it's not optimizable
2. reverse arrays while copying arguments instead of reversing afterwards
3. move creating executor to a common function and use it for both objects and strings
4. add a new executor for buffers
5. define context stuff for each executor in its own module (*-input.coffee)
6. add a `direct()` function which replaces all node name references with the actual node functions
7. change `defaultDone` in Control to return either the error or the result instead of throwing the error
8. create separate handling in Control for direct and non-direct modes
9. stop storing the current node in `_node` and only store its "after" nodes in `_after`
10. move try-catch to its own isolated function because it's not optimizable before Node 7 (right? 7? 6?)
11. revise readme code to hold more usage and add simpler examples of doing before/after changes.
12. make the README example a real runnable example in `examples/` directory
13. add coffeelint for linting
14. add code coverage via istanbul
15. change Travis config to also run in Node 7
16. change Travis to report code coverage to coveralls
17. change Travis to cache `node_modules/` directory
18. add year 2017 to LICENSE
19. update deps
20. added another example which uses `direct()`
21. added another example which uses buffers
22. added another example which uses a transform


## 0.1.0 - 2016/12/04

1. initial working version with (some) tests
