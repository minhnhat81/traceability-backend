
from app.utils.pagination import Page, PageMeta
def test_page_schema():
    p = Page(data=[1,2,3], meta=PageMeta(total=100, limit=10, offset=0))
    assert p.meta.total == 100
    assert p.data == [1,2,3]
