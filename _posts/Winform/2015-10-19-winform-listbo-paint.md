---
layout: post
title: winform下重画ListBox
categories: winform
description: winform下重画ListBox
keywords: winform下重画ListBox,winform,listbox
---
Windows Forms是由Win32 API封装的开发组件，最初是为了替代mfc，但却没有体现与Model View Controller架构对应的特色，进而在.net framework 3.0中推出了wpf，富控件数据显示方面，利用模板功能轻松实现。

在winform下要想自定义一些用户控件，就需要运用的2D绘画类。下图我们为ListBox重新排列了数据显示方式，并为每一个item加入了删除按钮。

1

首先我们设计一个承载数据的类ListBoxItem。
```java
public class ListBoxItem : IDisposable
{
    public Guid Id { get; set; }


    public string Name { get; set; }


    public string IP { get; set; }


    public string Mac { get; set; }


    [System.ComponentModel.DefaultValue(typeof(System.Drawing.Image), "null")]
    public System.Drawing.Image Image { get; set; }


    public bool IsFocus { get; set; }


    public ListBoxItem() { }


    public ListBoxItem(Guid id, string name, string ip, string mac, System.Drawing.Image image)
    {
        this.Id = id;
        this.Name = name;
        this.IP = ip;
        this.Mac = mac;
        this.Image = image;
        this.IsFocus = false;
    }


    public void Dispose()
    {
        this.Image = null;
    }
}
```
然后我们再为ListBox写一个用于展现数据的数据源ListBoxItemCollection，这里实现了迭代和集合操作接口，可以根据需要扩展数据操作方法。
```java
[System.ComponentModel.ListBindable(false)]
public class ListBoxItemCollection : IList, ICollection, IEnumerable
{
    private UserListBox m_owner;


    public ListBoxItemCollection(UserListBox owner)
    {
        this.m_owner = owner;
    }


    internal UserListBox Owner
    {
        get { return this.m_owner; }
    }


    #region  override
    public ListBoxItem this[int index]
    {
        get { return Owner.OldItemSource[index] as ListBoxItem; }
        set { Owner.OldItemSource[index] = value; }
    }


    public int Count
    {
        get { return Owner.OldItemSource.Count; }
    }


    public bool IsReadOnly
    {
        get { return Owner.OldItemSource.IsReadOnly; }
    }


    public int Add(ListBoxItem item)
    {
        if (item == null)
        {
            throw new ArgumentException("item is null");
        }
        return Owner.OldItemSource.Add(item);
    }


    public void AddRange(ListBoxItem[] items)
    {
        Owner.OldItemSource.AddRange(items);
    }


    public void Clear()
    {
        if (Owner.OldItemSource.Count > 0)
        {
            Owner.OldItemSource.Clear();
        }
    }


    public bool Contains(ListBoxItem item)
    {
        bool rst = false;
        foreach (ListBoxItem oldItem in Owner.OldItemSource)
        {
            if (oldItem.Id == item.Id)
            {
                rst = true;
                break;
            }
        }
        return rst;
    }


    public void CopyTo(ListBoxItem[] destination, int arrayIndex)
    {
        Owner.OldItemSource.CopyTo(destination, arrayIndex);
    }


    public int IndexOf(ListBoxItem item)
    {
        return Owner.OldItemSource.IndexOf(item);
    }


    public void Insert(int index, ListBoxItem item)
    {
        if (item == null)
        {
            throw new ArgumentException("item is null");
        }
        Owner.OldItemSource.Insert(index, item);
    }


    public void Remove(ListBoxItem item)
    {
        Owner.OldItemSource.Remove(item);
    }


    public void RemoveAt(int index)
    {
        Owner.OldItemSource.RemoveAt(index);
    }


    public IEnumerator GetEnumerator()
    {
        return Owner.OldItemSource.GetEnumerator();
    }


    int IList.Add(object value)
    {
        if (!(value is ListBoxItem))
        {
            throw new ArgumentException();
        }
        return Add(value as ListBoxItem);
    }


    void IList.Clear()
    {
        Clear();
    }


    bool IList.Contains(object value)
    {
        return Contains(value as ListBoxItem);
    }


    int IList.IndexOf(object value)
    {
        return IndexOf(value as ListBoxItem);
    }


    void IList.Insert(int index, object value)
    {
        if (!(value is ListBoxItem))
        {
            throw new ArgumentException();
        }
        Insert(index, value as ListBoxItem);
    }


    bool IList.IsFixedSize
    {
        get { return false; }
    }


    bool IList.IsReadOnly
    {
        get { return IsReadOnly; }
    }


    void IList.Remove(object value)
    {
        Remove(value as ListBoxItem);
    }


    void IList.RemoveAt(int index)
    {
        RemoveAt(index);
    }


    object IList.this[int index]
    {
        get { return this[index]; }
        set
        {
            if (!(value is ListBoxItem))
            {
                throw new ArgumentException();
            }
            this[index] = value as ListBoxItem;
        }
    }


    void ICollection.CopyTo(Array array, int index)
    {
        CopyTo((ListBoxItem[])array, index);
    }


    int ICollection.Count
    {
        get { return Count; }
    }


    bool ICollection.IsSynchronized
    {
        get { return false; }
    }


    object ICollection.SyncRoot
    {
        get { return false; }
    }


    IEnumerator IEnumerable.GetEnumerator()
    {
        return GetEnumerator();
    }
    #endregion


    #region  extention
    public ListBoxItem FindByMac(string mac)
    {
        foreach (ListBoxItem item in Owner.OldItemSource)
        {
            if (item.Mac == mac)
            {
                return item;
            }
        }
        return null;
    }
    #endregion
}
```
下面可以为工程new一个新项——自定义控件，命名为UserListBox。

这里有几个地方要说明一下，首先在默认构造函数里面的参数：

DrawMode.OwnerDrawVariable启用控件重绘功能。

DoubleBuffer开启后避免复杂绘画造成窗体闪烁，这个缓冲的原理是将绘画操作放在内存里操作，完成后才会复制到图形界面上，进而避免的闪烁。

OnPaint进行了重写，这个方法是根据pc屏幕分辨率刷新频率来执行的，会不断的重复执行，进而持久化图形界面。

Invalidate方法，会立即刷新UI。

Item上的按钮事件，是通过ListBox的click事件，取到鼠标的在界面上的定位，调用相对应的方法。

```java
public partial class UserListBox : ListBox
{
    public ListBoxItem mouseItem;
    private ListBoxItemCollection m_Items;


    public UserListBox() : base()
    {
        InitializeComponent();


        m_Items = new ListBoxItemCollection(this);


        base.DrawMode = DrawMode.OwnerDrawVariable;
        this.SetStyle(ControlStyles.UserPaint, true);
        this.SetStyle(ControlStyles.DoubleBuffer, true); // 双缓冲
        this.SetStyle(ControlStyles.OptimizedDoubleBuffer, true); // 双缓冲   
        this.SetStyle(ControlStyles.ResizeRedraw, true); // 调整大小时重绘
        this.SetStyle(ControlStyles.AllPaintingInWmPaint, true); // 禁止擦除背景. 
        this.SetStyle(ControlStyles.SupportsTransparentBackColor, true); // 开启控件透明
    }


    public new ListBoxItemCollection Items
    {
        get { return m_Items; }
    }


    internal ListBox.ObjectCollection OldItemSource
    {
        get { return base.Items; }
    }


    protected override void OnPaint(PaintEventArgs e)
    {
        Graphics g = e.Graphics;
        
        // you can set SeletedItem background
        if (this.Focused && this.SelectedItem != null)
        {
        }


        for (int i = 0; i < Items.Count; i++)
        {
            Rectangle bounds = this.GetItemRectangle(i);


            if (mouseItem == Items[i])
            {
                Color leftColor = Color.FromArgb(200, 192, 224, 248);
                using (SolidBrush brush = new SolidBrush(leftColor))
                {
                    g.FillRectangle(brush, new Rectangle(bounds.X, bounds.Y, bounds.Width, bounds.Height));
                }


                Color rightColor = Color.FromArgb(252, 233, 161);
                using (SolidBrush brush = new SolidBrush(rightColor))
                {
                    g.FillRectangle(brush, new Rectangle(bounds.Width - 40, bounds.Y, 40, bounds.Height));
                }
            }


            int fontLeft = bounds.Left + 40 + 15;
            System.Drawing.Font font = new System.Drawing.Font("微软雅黑", 9);
            g.DrawString(Items[i].Name, font, new SolidBrush(this.ForeColor), fontLeft, bounds.Top + 5);
            g.DrawString(Items[i].IP, font, new SolidBrush(Color.FromArgb(128, 128, 128)), fontLeft, bounds.Top + 20);
            g.DrawString(Items[i].Mac, font, new SolidBrush(Color.FromArgb(128, 128, 128)), fontLeft, bounds.Top + 35);


            if (Items[i].Image != null)
            {
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
                g.DrawImage(Items[i].Image, new Rectangle(bounds.X + 5, (bounds.Height - 40) / 2 + bounds.Top, 40, 40));
            }
            g.DrawImage(Properties.Resources.error, new Rectangle(bounds.Width - 28, (bounds.Height - 16) / 2 + bounds.Top, 16, 16));
        }
        base.OnPaint(e);
    }


    protected override void OnMeasureItem(MeasureItemEventArgs e)
    {
        base.OnMeasureItem(e);
        if (Items.Count > 0)
        {
            ListBoxItem item = Items[e.Index];
            e.ItemHeight = 54;
        }
        
    }


    protected override void OnSelectedIndexChanged(EventArgs e)
    {
        base.OnSelectedIndexChanged(e);
    }


    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        for (int i = 0; i < Items.Count; i++)
        {
            Rectangle bounds = this.GetItemRectangle(i);
            Rectangle deleteBounds = new Rectangle(bounds.Width - 28, (bounds.Height - 16) / 2 + bounds.Top, 16, 16);


            if (bounds.Contains(e.X, e.Y))
            {
                if (Items[i] != mouseItem)
                {
                    mouseItem = Items[i];
                }


                if (deleteBounds.Contains(e.X, e.Y))
                {
                    mouseItem.IsFocus = true;
                    this.Cursor = Cursors.Hand;
                }
                else
                {
                    mouseItem.IsFocus = false;
                    this.Cursor = Cursors.Arrow;
                }


                this.Invalidate();
                break;
            }
        }
    }


    protected override void OnMouseClick(MouseEventArgs e)
    {
        base.OnMouseClick(e);
        if (mouseItem.IsFocus)
        {
            ListBoxItem deleteItem = mouseItem;
            if(MessageBox.Show("confirm to delete", "", MessageBoxButtons.OKCancel) == DialogResult.OK)
            {
                this.Items.Remove(deleteItem);
            }
        }
    }


    protected override void OnMouseLeave(EventArgs e)
    {
        base.OnMouseLeave(e);
        this.mouseItem = null;
        this.Invalidate();
    }
}
```