using NLopt

count = 0 # keep track of # function evaluations

function myfunc(x::Vector, grad::Vector)
    global count
    count::Int += 1

    res = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
    println("f_$count($x)=$res")
    return res
end

function myconstraint(x::Vector, grad::Vector, a, b)
    if length(grad) > 0
        grad[1] = 3a * (a*x[1] + b)^2
        grad[2] = -1
    end
    (a*x[1] + b)^3 - x[2]
end

#opt = Opt(:LN_NELDERMEAD, 2)
#opt = Opt(:GN_DIRECT_L, 2)
opt = Opt(:GN_ESCH, 2)
lower_bounds!(opt, [-10.0, -10.0])
upper_bounds!(opt, [10.0, 10.0])
xtol_rel!(opt,1e-6)
ftol_rel!(opt,1e-6)
ftol_abs!(opt,1e-16)

min_objective!(opt, myfunc)
#inequality_constraint!(opt, (x,g) -> myconstraint(x,g,2,0), 1e-8)
#inequality_constraint!(opt, (x,g) -> myconstraint(x,g,-1,1), 1e-8)

(minf,minx,ret) = optimize(opt, [0.0, 0.0])
println("got $minf at $minx after $count iterations (returned $ret)")
