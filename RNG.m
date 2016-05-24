function[ numbers ] = RNG(m,seed,a,c)
    numbers(1)=seed;
    for i=2:m
        u=mod(a*numbers(i-1)+c, m);
        numbers(i)=u;
    end
    numbers=numbers./m;
  