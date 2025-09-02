def master_fn(input_fn):
    print("I am master decorator. I decorate functions.")

    def intermediate_fn():
       print("  I am an intermediate. I am under master.")     
       print("".rjust(100,'*'))
       input_fn()
       print("  Master fn Finished now.")

    return  intermediate_fn

@master_fn
def decoratee():
    print("         I am eager to get decorated.")

decoratee()
