util    = require "util"
express = require "express"
errify  = require "errify"
extend  = util._extend


## Helping Models REST since 1981

class Xanax
  constructor: ({@Model, @name, @router}) ->
    @name   or= "#{@Model.className.toLowerCase()}s"
    @router or= new express.Router

    @router.get    "/#{@name}", @index
    @router.post   "/#{@name}", @create
    # @router.put    @name, @updateMany
    @router.get    "/#{@name}/new", @new
    @router.get    "/#{@name}/:id", @find, @read
    @router.get    "/#{@name}/:id/edit", @find, @edit
    @router.put    "/#{@name}/:id", @find, @update
    @router.patch  "/#{@name}/:id", @find, @patch
    @router.delete "/#{@name}/:id", @find, @delete

    @paths = {}
    @paths[path] = fn.call this for path, fn of @constructor.paths

  @paths:
    index:  -> "#{@name}/index"
    create: -> "#{@name}/create"
    new:    -> "#{@name}/new"
    show:   -> "#{@name}/show"
    edit:   -> "#{@name}/edit"
    update: -> "#{@name}/update"
    patch:  -> "#{@name}/patch"
    delete: -> "#{@name}/delete"

  respond: (res, path, records...) =>
    if records.length is 1 and path isnt @paths.index
      [record] = records
      response = record.attributes()
    else
      response = (record.attributes() for record in records)

    @render res, path, response

  render: (res, path, response) -> res.render path, response

  index: (req, res, next) =>
    ideally = errify next
    {query} = req
    key = value = null
    do -> return delete query[key] for key, value of query when key in @Model.attributes
    if key
      await @Model.findAllByAttribute key, value, query, ideally defer records
    else
      await @Model.findAll query, ideally defer records

    @respond res, @paths.index, records...

  create: (req, res, next) =>
    ideally = errify next
    record  = new @Model req.body
    await record.save ideally defer record
    @respond res, @paths.create, record

  new: (req, res, next) =>
    @respond res, @paths.new, new @Model

  find: (req, res, next) =>
    ideally = errify next
    await @Model.find req.params.id, ideally defer record
    res.locals.record = record
    next()

  read: (req, res, next) =>
    @respond res, @paths.show, res.locals.record

  edit: (req, res, next) =>
    @respond res, @paths.edit, res.locals.record

  update: (req, res, next) =>
    ideally  = errify next
    {record} = res.locals
    delete req.body.id
    record.load req.body
    await record.save ideally defer record
    @respond res, @paths.update, record

  patch: (req, res, next) =>
    ideally  = errify next
    {record} = res.locals
    extend record, req.body
    await record.save ideally defer record
    @respond res, @paths.patch, record

  delete: (req, res, next) =>
    ideally  = errify next
    {record} = res.locals
    await record.remove ideally defer record
    @respond res, @paths.delete


module.exports = Xanax
