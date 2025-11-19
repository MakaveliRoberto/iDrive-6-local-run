function foldTreeNode(id)
{
    if(document.getElementsByClassName(id)[0].style.display=='none')
    {
        for(e of document.getElementsByClassName('p'+id))
        {
            e.style.display = 'table-row';
        }
    }else{
        for(e of document.getElementsByClassName(id))
        {
            e.style.display = 'none';
        }
    }
}
