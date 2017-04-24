--[[
  Lua port of the Hacker Disassembler Engine 64

  The Hacker Disassembler Engine is made by Vyacheslav Patkov
  Copyright (c) 2008-2009
  All rights reserved.
--]]

local hde = {}

local defines = {
    F_MODRM             = 0x00000001,
    F_SIB               = 0x00000002,
    F_IMM8              = 0x00000004,
    F_IMM16             = 0x00000008,
    F_IMM32             = 0x00000010,
    F_IMM64             = 0x00000020,
    F_DISP8             = 0x00000040,
    F_DISP16            = 0x00000080,
    F_DISP32            = 0x00000100,
    F_RELATIVE          = 0x00000200,
    F_ERROR             = 0x00001000,
    F_ERROR_OPCODE      = 0x00002000,
    F_ERROR_LENGTH      = 0x00004000,
    F_ERROR_LOCK        = 0x00008000,
    F_ERROR_OPERAND     = 0x00010000,
    F_PREFIX_REPNZ      = 0x01000000,
    F_PREFIX_REPX       = 0x02000000,
    F_PREFIX_REP        = 0x03000000,
    F_PREFIX_66         = 0x04000000,
    F_PREFIX_67         = 0x08000000,
    F_PREFIX_LOCK       = 0x10000000,
    F_PREFIX_SEG        = 0x20000000,
    F_PREFIX_REX        = 0x40000000,
    F_PREFIX_ANY        = 0x7f000000,

    PREFIX_SEGMENT_CS   = 0x2e,
    PREFIX_SEGMENT_SS   = 0x36,
    PREFIX_SEGMENT_DS   = 0x3e,
    PREFIX_SEGMENT_ES   = 0x26,
    PREFIX_SEGMENT_FS   = 0x64,
    PREFIX_SEGMENT_GS   = 0x65,
    PREFIX_LOCK         = 0xf0,
    PREFIX_REPNZ        = 0xf2,
    PREFIX_REPX         = 0xf3,
    PREFIX_OPERAND_SIZE = 0x66,
    PREFIX_ADDRESS_SIZE = 0x67,

    C_NONE              = 0x00,
    C_MODRM             = 0x01,
    C_IMM8              = 0x02,
    C_IMM16             = 0x04,
    C_IMM_P66           = 0x10,
    C_REL8              = 0x20,
    C_REL32             = 0x40,
    C_GROUP             = 0x80,
    C_ERROR             = 0xff,

    PRE_ANY             = 0x00,
    PRE_NONE            = 0x01,
    PRE_F2              = 0x02,
    PRE_F3              = 0x04,
    PRE_66              = 0x08,
    PRE_67              = 0x10,
    PRE_LOCK            = 0x20,
    PRE_SEG             = 0x40,
    PRE_ALL             = 0xff,

    DELTA_OPCODES       = 0x4a,
    DELTA_FPU_REG       = 0xfd,
    DELTA_FPU_MODRM     = 0x104,
    DELTA_PREFIXES      = 0x13c,
    DELTA_OP_LOCK_OK    = 0x1ae,
    DELTA_OP2_LOCK_OK   = 0x1c6,
    DELTA_OP_ONLY_MEM   = 0x1d8,
    DELTA_OP2_ONLY_MEM  = 0x1e7
}

local hde64_table = {
[0] = 0xa5,0xaa,0xa5,0xb8,0xa5,0xaa,0xa5,0xaa,0xa5,0xb8,0xa5,0xb8,0xa5,0xb8,0xa5,
      0xb8,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xac,0xc0,0xcc,0xc0,0xa1,0xa1,
      0xa1,0xa1,0xb1,0xa5,0xa5,0xa6,0xc0,0xc0,0xd7,0xda,0xe0,0xc0,0xe4,0xc0,0xea,
      0xea,0xe0,0xe0,0x98,0xc8,0xee,0xf1,0xa5,0xd3,0xa5,0xa5,0xa1,0xea,0x9e,0xc0,
      0xc0,0xc2,0xc0,0xe6,0x03,0x7f,0x11,0x7f,0x01,0x7f,0x01,0x3f,0x01,0x01,0xab,
      0x8b,0x90,0x64,0x5b,0x5b,0x5b,0x5b,0x5b,0x92,0x5b,0x5b,0x76,0x90,0x92,0x92,
      0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x6a,0x73,0x90,
      0x5b,0x52,0x52,0x52,0x52,0x5b,0x5b,0x5b,0x5b,0x77,0x7c,0x77,0x85,0x5b,0x5b,
      0x70,0x5b,0x7a,0xaf,0x76,0x76,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,0x5b,
      0x5b,0x5b,0x86,0x01,0x03,0x01,0x04,0x03,0xd5,0x03,0xd5,0x03,0xcc,0x01,0xbc,
      0x03,0xf0,0x03,0x03,0x04,0x00,0x50,0x50,0x50,0x50,0xff,0x20,0x20,0x20,0x20,
      0x01,0x01,0x01,0x01,0xc4,0x02,0x10,0xff,0xff,0xff,0x01,0x00,0x03,0x11,0xff,
      0x03,0xc4,0xc6,0xc8,0x02,0x10,0x00,0xff,0xcc,0x01,0x01,0x01,0x00,0x00,0x00,
      0x00,0x01,0x01,0x03,0x01,0xff,0xff,0xc0,0xc2,0x10,0x11,0x02,0x03,0x01,0x01,
      0x01,0xff,0xff,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0xff,0xff,0xff,0xff,0x10,
      0x10,0x10,0x10,0x02,0x10,0x00,0x00,0xc6,0xc8,0x02,0x02,0x02,0x02,0x06,0x00,
      0x04,0x00,0x02,0xff,0x00,0xc0,0xc2,0x01,0x01,0x03,0x03,0x03,0xca,0x40,0x00,
      0x0a,0x00,0x04,0x00,0x00,0x00,0x00,0x7f,0x00,0x33,0x01,0x00,0x00,0x00,0x00,
      0x00,0x00,0xff,0xbf,0xff,0xff,0x00,0x00,0x00,0x00,0x07,0x00,0x00,0xff,0x00,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0xff,
      0x00,0x00,0x00,0xbf,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7f,0x00,0x00,
      0xff,0x40,0x40,0x40,0x40,0x41,0x49,0x40,0x40,0x40,0x40,0x4c,0x42,0x40,0x40,
      0x40,0x40,0x40,0x40,0x40,0x40,0x4f,0x44,0x53,0x40,0x40,0x40,0x44,0x57,0x43,
      0x5c,0x40,0x60,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,
      0x40,0x40,0x64,0x66,0x6e,0x6b,0x40,0x40,0x6a,0x46,0x40,0x40,0x44,0x46,0x40,
      0x40,0x5b,0x44,0x40,0x40,0x00,0x00,0x00,0x00,0x06,0x06,0x06,0x06,0x01,0x06,
      0x06,0x02,0x06,0x06,0x00,0x06,0x00,0x0a,0x0a,0x00,0x00,0x00,0x02,0x07,0x07,
      0x06,0x02,0x0d,0x06,0x06,0x06,0x0e,0x05,0x05,0x02,0x02,0x00,0x00,0x04,0x04,
      0x04,0x04,0x05,0x06,0x06,0x06,0x00,0x00,0x00,0x0e,0x00,0x00,0x08,0x00,0x10,
      0x00,0x18,0x00,0x20,0x00,0x28,0x00,0x30,0x00,0x80,0x01,0x82,0x01,0x86,0x00,
      0xf6,0xcf,0xfe,0x3f,0xab,0x00,0xb0,0x00,0xb1,0x00,0xb3,0x00,0xba,0xf8,0xbb,
      0x00,0xc0,0x00,0xc1,0x00,0xc7,0xbf,0x62,0xff,0x00,0x8d,0xff,0x00,0xc4,0xff,
      0x00,0xc5,0xff,0x00,0xff,0xff,0xeb,0x01,0xff,0x0e,0x12,0x08,0x00,0x13,0x09,
      0x00,0x16,0x08,0x00,0x17,0x09,0x00,0x2b,0x09,0x00,0xae,0xff,0x07,0xb2,0xff,
      0x00,0xb4,0xff,0x00,0xb5,0xff,0x00,0xc3,0x01,0x00,0xc7,0xff,0xbf,0xe7,0x08,
      0x00,0xf0,0x02,0x00
}

---[[ hde64s class
local hde64s = { len = -1,
                 p_rep = -1,
                 p_lock = -1,
                 p_seg =-1,
                 p_66 = -1,
                 p_67 = -1,
                 rex = -1,
                 rex_w = -1,
                 rex_r = -1,
                 rex_x = -1,
                 rex_b = -1,
                 opcode = -1,
                 opcode2 = -1,
                 modrm = -1,
                 modrm_mod = -1,
                 modrm_reg = -1,
                 modrm_rm = -1,
                 sib = -1,
                 sib_scale = -1,
                 sib_index = -1,
                 sib_base = -1,
                 imm = { imm8  = -1,
                         imm16 = -1,
                         imm32 = -1,
                         imm64 = -1 },
                disp = { disp8  = -1,
                         disp16 = -1,
                         disp32 = -1 },
                flags = -1
}

function hde64s:new (o)
  o = o or {}  -- create object if required
  setmetatable(o, self)
  self.__index = self
  self.imm = { imm8  = -1,
               imm16 = -1,
               imm32 = -1,
               imm64 = -1 }
  self.disp = { disp8  = -1,
                disp16 = -1,
                disp32 = -1 }
  return o
end

function hde64s:dump()
  print("len:", self.len)
  print(string.format("opcode: %x", self.opcode))
  print(string.format("opcode2: %x", self.opcode2))
  if self.imm.imm8 ~= -1 then
    print(string.format("imm8: %x", self.imm.imm8))
  end
  if self.imm.imm16 ~= -1 then
    print(string.format("imm16: %x", self.imm.imm16))
  end
  if self.imm.imm32 ~= -1 then
    print(string.format("imm32: %x", self.imm.imm32))
  end
  if self.imm.imm64 ~= -1 then
    print(string.format("imm64: %x", self.imm.imm64))
  end
  print(string.format("flags: %x", self.flags))
end
---]]

function hde.disasm(code)
  local hs = hde64s:new()
  local p = code
  local ht = hde64_table
  local x, c, cflags, opcode, pref = 0, 0, 0, 0, 0
  local m_mod, m_reg, m_rm, disp_size = 0, 0, 0, 0
  local op64 = 0

  local pc = 0 -- 'program counter', keeps track of where we are in p
  local tc = 0 -- 'table counter', keeps track of where we are in ht

  for x=16,1,-1 do
    c = p[pc]
    pc = pc + 1
    if c == 0xf3 then
      hs.p_rep = c
      pref = pref | defines.PRE_F3
    elseif c == 0xf2 then
      hs.p_rep = c
      pref = pref | defines.PRE_F2
    elseif c == 0xf0 then
      hs.p_lock = c
      pref = pref | defines.PRE_LOCK
    elseif c == 0x26 or
           c == 0x2e or
           c == 0x36 or
           c == 0x3e or
           c == 0x64 or
           c == 0x65 then
      hs.p_seg = c
      pref = pref | defines.PRE_SEG
    elseif c == 0x66 then
      hs.p_66 = c
      pref = pref | defines.PRE_66
    elseif c == 0x67 then
      hs.p_67 = c
      pref = pref | defines.PRE_67
    else
      break
    end
  end

  hs.flags = pref << 23
  if pref == 0 then
    pref = pref | defines.PRE_NONE
  end

  if (c & 0xf0) == 0x40 then
    hs.flags = hs.flags | defines.F_PREFIX_REX
    hs.rex_w = (c & 0xf) >> 3
    if (hs.rex_w ~= 0 and (p[pc] & 0xf8) == 0xb8) then
      op64 = op64 + 1;
    end
    hs.rex_r = (c & 7) >> 2
    hs.rex_x = (c & 3) >> 1
    hs.rex_b = (c & 1)
    c = p[pc]
    pc = pc + 1
    if (c & 0xf0) == 0x40 then
      opcode = c
      hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_OPCODE
      cflags = 0
      if (opcode & -3) == 0x24 then
        cflags = cflags + 1
      end
      goto error_opcode
    end
  end

  hs.opcode = c
  if hs.opcode == 0x0f then
    c = p[pc]
    pc = pc + 1
    hs.opcode2 = c
    tc = tc + defines.DELTA_OPCODES
  elseif c >= 0xa0 and c <= 0xa3 then
    op64 = op64 + 1
    if (pref & defines.PRE_67) ~= 0 then
      pref = pref | defines.PRE_66
    else
      pref = pref & ~defines.PRE_66
    end
  end

  opcode = c
  cflags = ht[math.floor(tc + ht[math.floor(tc + opcode / 4)] + (opcode % 4))]

  if cflags == defines.C_ERROR then
    hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_OPCODE
    cflags = 0
    if (opcode & -3) == 0x24 then
      cflags = cflags + 1
    end
  end
  ::error_opcode::

  x = 0
  if (cflags & defines.C_GROUP) ~= 0 then
    x = ht[tc + (cflags & 0x7f) + 1]
    cflags = ht[tc + (cflags & 0x7f)]
  end

  if hs.opcode2 ~= 0 then
    tc = defines.DELTA_PREFIXES
    if (ht[math.floor(tc + ht[math.floor(tc + opcode / 4)] + (opcode % 4))] & pref) ~= 0 then
      hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_OPCODE
    end
  end

  if cflags & defines.C_MODRM ~= 0 then
    hs.flags = hs.flags | defines.F_MODRM
    c = p[pc]
    pc = pc + 1
    hs.modrm = c
    m_mod = c >> 6
    hs.modrm_mod = m_mod
    m_rm = c & 7
    hs.modrm_rm = m_rm
    m_reg = (c & 0x3f) >> 3
    hs.modrm_reg = m_reg

    if x ~= 0 and ((x << m_reg) & 0x80) ~= 0 then
      hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_OPCODE
    end

    if hs.opcode2 == 0 and opcode >= 0xd9 and opcode <= 0xdf then
      local t = (opcode - 0xd9) & 0xff
      if m_mod == 3 then
        tc = defines.DELTA_FPU_MODRM + t*8
        t = ht[tc + m_reg] << m_rm
      else
        tc = defines.DELTA_FPU_REG
        t = ht[tc + t] << m_reg
      end

      if (t & 0x80) ~= 0 then
        hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_OPCODE
      end
    end

    if (pref & defines.PRE_LOCK) ~= 0 then
      if m_mod == 3 then
        hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_LOCK
      else
        local op = opcode
        local table_end

        if hs.opcode2 ~= 0 then
          tc = defines.DELTA_OP2_LOCK_OK
          table_end = tc + defines.DELTA_OP_ONLY_MEM - defines.DELTA_OP2_LOCK_OK
        else
          tc = defines.DELTA_OP_LOCK_OK
          table_end = tc + defines.DELTA_OP2_ONLY_MEM - defines.DELTA_OP_LOCK_OK
          op = op & -2
        end

        while tc ~= table_end do
          if ht[tc] == op then
            if ((ht[tc + 1] << m_reg) & 0x80) == 0 then
              goto no_lock_error
            else
              break
            end
          end
          tc = tc + 2
        end

        hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_LOCK
        ::no_lock_error::
      end
    end

    if hs.opcode2 ~= 0 then
      if opcode == 0x20 or opcode == 0x22 then
        m_mod = 3
        if m_reg > 4 or m_reg == 1 then
          goto error_operand
        else
          goto no_error_operand
        end
      elseif opcode == 0x21 or opcode == 0x23 then
        m_mod = 3
        if m_reg == 4 or m_reg == 5 then
          goto error_operand
        else
          goto no_error_operand
        end
      end
    else
      if opcode == 0x8c then
        if m_reg > 5 then
          goto error_operand
        else
          goto no_error_operand
        end
      elseif opcode == 0x8e then
        if m_reg == 1 or m_reg > 5 then
          goto error_operand
        else
          goto no_error_operand
        end
      end
    end

    if m_mod == 3 then
      local table_end
      if hs.opcode2 ~= 0 then
        tc = defines.DELTA_OP2_ONLY_MEM
        table_end = tc + #hde64_table + 1 - defines.DELTA_OP2_ONLY_MEM -- +1 because of how table size works in Lua
      else
        tc = defines.DELTA_OP_ONLY_MEM
        table_end = tc + defines.DELTA_OP2_ONLY_MEM - defines.DELTA_OP_ONLY_MEM
      end

      while tc ~= table_end do
        if ht[tc] == opcode then
          local temp = ht[tc+1] & pref
          tc = tc + 1
          if tmp ~= 0 and ((ht[tc + 1] << m_reg) & 0x80) == 0 then
            goto error_operand
          else
            break
          end
        end
        tc = tc + 3
      end
      goto no_error_operand
    elseif hs.opcode2 ~= 0 then
      if opcode == 0x50 or opcode == 0xd7 or opcode == 0xf7 then
        if (pref & (defines.PRE_NONE | defines.PRE_66)) ~= 0 then
          goto error_operand
        end
      elseif opcode == 0xd6 then
        if (pref & (defines.PRE_F2 | defines.PRE_F3)) ~= 0 then
          goto error_operand
        end
      elseif opcode == 0xc5 then
        goto error_operand
      end
      goto no_error_operand
    else
      goto no_error_operand
    end

    ::error_operand::
    hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_OPERAND
    ::no_error_operand::

    c = p[pc]
    pc = pc + 1
    if m_reg <= 1 then
      if opcode == 0xf6 then
        cflags = cflags | defines.C_IMM8
      elseif opcode == 0xf7 then
        cflags = cflags | defines.C_IMM_P66
      end
    end

    if m_mod == 0 then
      if (pref & defines.PRE_67) ~= 0 then
        if m_rm == 6 then
          disp_size = 2
        end
      else
        if m_rm == 5 then
          disp_size = 4
        end
      end
    elseif m_mod == 1 then
      disp_size = 1
    elseif m_mod == 2 then
      disp_size = 2
      if (pref & defines.PRE_67) == 0 then
        disp_size = disp_size << 1
      end
    end

    if m_mod ~= 3 and m_rm == 4 and c ~= nil then
      hs.flags = hs.flags | defines.F_SIB
      pc = pc + 1
      hs.sib = c
      hs.sib_scale = c >> 6
      hs.sib_index = (c & 0x3f) >> 3
      hs.sib_base = c & 7
      if hs.sib_base == 5 and (m_mod & 1) == 0 then
        disp_size = 4
      end
    end

    pc = pc - 1

    if disp_size == 1 then
      hs.flags = hs.flags | defines.F_DISP8
      hs.disp.disp8 = p[pc]
    elseif disp_size == 2 then
      hs.flags = hs.flags | defines.F_DISP16
      hs.disp.disp16 = (p[pc] << 8) + p[pc+1]
    elseif disp_size == 4 then
      hs.flags = hs.flags | defines.F_DISP32
      hs.disp.disp32 = (p[pc + 3] << 24) + (p[pc+2] << 16) + (p[pc+1] << 8) + p[pc]
    end

    pc = pc + disp_size

  elseif (pref & defines.PRE_LOCK) ~= 0 then
    hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_LOCK
  end

  if (cflags & defines.C_IMM_P66) ~= 0 then
    if (cflags & defines.C_REL32) ~= 0 then
      if (pref & defines.PRE_66) ~= 0 then
        hs.flags = hs.flags | defines.F_IMM16 | defines.F_RELATIVE
        hs.imm.imm16 = (p[pc + 1] << 8) + p[pc]
        pc = pc + 2
        goto disasm_done
      end
      hs.flags = hs.flags | defines.F_IMM32 | defines.F_RELATIVE
      hs.imm.imm32 = (p[pc+3] << 24) + (p[pc+2] << 16) + (p[pc+1] << 8) + p[pc]
      pc = pc + 4
      goto rel32_ok
    end
    if op64 ~= 0 then
      hs.flags = hs.flags | defines.F_IMM64
      hs.imm.imm64 = (p[pc+7] << 56) + (p[pc+6] << 48) + (p[pc+5] << 40) + (p[pc+4] << 32)
                   + (p[pc+3] << 24) + (p[pc+2] << 16) + (p[pc+1] << 8) + p[pc]
      pc = pc + 8
    elseif (pref & defines.PRE_66) == 0 then
      hs.flags = hs.flags | defines.F_IMM32
      hs.imm.imm32 = (p[pc+3] << 24) + (p[pc+2] << 16) + (p[pc+1] << 8) + p[pc]
      pc = pc + 4
    else
      hs.flags = hs.flags | defines.F_IMM16
      hs.imm.imm16 = (p[pc+1] << 8) + p[pc]
      pc = pc + 2
      goto imm16_ok
    end
  end

  if (cflags & defines.C_IMM16) ~= 0 then
    hs.flags = hs.flags | defines.F_IMM16
    hs.imm.imm16 = (p[pc+1] << 8) + p[pc]
    pc = pc + 2
  end
  ::imm16_ok::

  if (cflags & defines.C_IMM8) ~= 0 then
    hs.flags = hs.flags | defines.F_IMM8
    hs.imm.imm8 = p[pc]
    pc = pc + 1
  end

  if (cflags & defines.C_REL32) ~= 0 then
    hs.flags = hs.flags | defines.F_IMM32 | defines.F_RELATIVE
    hs.imm.imm32 = (p[pc+3] << 24) + (p[pc+2] << 16) + (p[pc+1] << 8) + p[pc]
    pc = pc + 4
  end
  ::rel32_ok::

  if (cflags & defines.C_REL8) ~= 0 then
    hs.flags = hs.flags | defines.F_IMM8 | defines.F_RELATIVE
    hs.imm.imm8 = p[pc]
    pc = pc + 1
  end

  ::disasm_done::
  hs.len = pc
  if hs.len > 15 then
    hs.flags = hs.flags | defines.F_ERROR | defines.F_ERROR_LENGTH
    hs.len = 15
  end

  return hs.len, hs
end

return hde
