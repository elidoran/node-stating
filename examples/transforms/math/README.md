# Example: transform

Transforms series of math operations and numbers into results.

Uses nodes:

1. **start** - determines what to do based on the input
2. **op** - stores the op in the context
3. **isOverwrite** - protects against overwriting the op
4. **value** - accumulates values in the context
5. **ready?** - tests if we have an op and at least two values to calculate a result
6. **calculate** - applies the op to all the values and pushes the result
7. **reset** - nulls the op and values to prepare for new ones
8. **error** - handles an error


Shows features:

1. building a transform
2. writing objects to the transform for processing
3. pushing results to the transform
4. using before and after to apply node pathing
5. shows `control.fail()` to handle errors


Try it:

```sh
npm run math
```
