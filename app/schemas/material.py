from pydantic import BaseModel
from typing import List, Optional, Union

class MaterialBase(BaseModel):
    tenant_id: int
    name: str
    scientific_name: Optional[str] = None
    stages: Optional[Union[List[str], str]] = None
    dpp_notes: Optional[str] = None

class MaterialCreate(MaterialBase):
    pass

class MaterialUpdate(BaseModel):
    name: Optional[str]
    scientific_name: Optional[str]
    stages: Optional[Union[List[str], str]]
    dpp_notes: Optional[str]

class MaterialRead(MaterialBase):
    id: int

    class Config:
        orm_mode = True
