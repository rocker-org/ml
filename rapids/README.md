

```python
import polars as pl

ldf = pl.LazyFrame({"a": [1.242, 1.535]})

print(
    ldf.select(
        pl.col("a").round(1)
    ).collect(engine="gpu")
)
```
