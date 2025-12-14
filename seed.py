from app.core.db import SessionLocal, engine
from app.models.product import Product
from app.models.batch import Batch
from app.models.event import Event
from sqlalchemy import text
from datetime import date

def run():
    db = SessionLocal()
    try:
        if not db.query(Product).first():
            db.add_all([
                Product(code="TSHIRT-001", name="T-Shirt Cotton", category="Top"),
                Product(code="JEANS-501", name="Denim Jeans", category="Bottom"),
            ])
        if not db.query(Batch).first():
            db.add_all([
                Batch(code="BATCH-2025-001", product_code="TSHIRT-001", mfg_date=date(2025, 1, 15), country="VN"),
                Batch(code="BATCH-2025-002", product_code="JEANS-501", mfg_date=date(2025, 2, 20), country="VN"),
            ])
        db.commit()
    finally:
        db.close()

if __name__ == "__main__":
    run()
